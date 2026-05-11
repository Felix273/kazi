from rest_framework.views import APIView
from rest_framework.generics import RetrieveUpdateAPIView, ListAPIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D

from apps.users.models import User, Skill, WorkerProfile
from apps.users.serializers import (
    UserSerializer, UpdateProfileSerializer,
    UpdateLocationSerializer, UpdateFCMTokenSerializer, SkillSerializer,
    KYCSubmitSerializer
)
from apps.users.services.kyc_service import KYCService
from rest_framework.permissions import AllowAny


class MyProfileView(RetrieveUpdateAPIView):
    """Get or update the logged-in user's profile"""
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        serializer = UpdateProfileSerializer(
            request.user, data=request.data, partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UpdateLocationView(APIView):
    """Update worker's current GPS location — called periodically by the app"""

    def post(self, request):
        serializer = UpdateLocationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user = request.user
        user.location = Point(data['longitude'], data['latitude'], srid=4326)
        if 'location_name' in data:
            user.location_name = data['location_name']
        user.save(update_fields=['location', 'location_name'])

        return Response({'detail': 'Location updated.'})


class UpdateFCMTokenView(APIView):
    """Store device FCM token for push notifications"""

    def post(self, request):
        serializer = UpdateFCMTokenSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        request.user.fcm_token = serializer.validated_data['fcm_token']
        request.user.save(update_fields=['fcm_token'])
        return Response({'detail': 'FCM token updated.'})


class SetOnlineStatusView(APIView):
    """Workers toggle their online/available status"""

    def post(self, request):
        is_online = request.data.get('is_online', False)
        request.user.is_online = is_online
        request.user.save(update_fields=['is_online'])

        # Also update worker profile availability
        if hasattr(request.user, 'worker_profile'):
            request.user.worker_profile.is_available = is_online
            request.user.worker_profile.save(update_fields=['is_available'])

        return Response({'is_online': is_online})


class NearbyWorkersView(APIView):
    """Get workers near a given location — used by employers when posting jobs"""

    def get(self, request):
        lat = request.query_params.get('lat')
        lng = request.query_params.get('lng')
        radius_km = float(request.query_params.get('radius', 10))
        skill_id = request.query_params.get('skill')

        if not lat or not lng:
            return Response(
                {'detail': 'lat and lng are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user_location = Point(float(lng), float(lat), srid=4326)

        workers = User.objects.filter(
            user_type__in=['worker', 'both'],
            is_online=True,
            is_active=True,
            location__isnull=False,
            location__dwithin=(user_location, D(km=radius_km))
        ).annotate(
            distance=Distance('location', user_location)
        ).order_by('distance')

        if skill_id:
            workers = workers.filter(worker_profile__skills__id=skill_id)

        serializer = UserSerializer(workers[:20], many=True)
        return Response(serializer.data)


class PublicProfileView(APIView):
    """View another user's public profile"""

    def get(self, request, user_id):
        try:
            user = User.objects.get(id=user_id, is_active=True)
        except User.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(UserSerializer(user).data)


class SkillListView(ListAPIView):
    """List all available skills/categories"""
    serializer_class = SkillSerializer
    permission_classes = []  # Public endpoint

    def get_queryset(self):
        category = self.request.query_params.get('category')
        qs = Skill.objects.all().order_by('category', 'name')
        if category:
            qs = qs.filter(category=category)
        return qs


class KYCSubmitView(APIView):
    """Submit KYC details for verification"""

    def post(self, request):
        serializer = KYCSubmitSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user = request.user

        # Save ID number to user model
        user.national_id_number = data['id_number']
        user.save(update_fields=['national_id_number'])

        # If photo is provided, save it to worker profile (if it exists)
        if 'id_photo' in data and hasattr(user, 'worker_profile'):
            user.worker_profile.id_document = data['id_photo']
            user.worker_profile.save(update_fields=['id_document'])

        try:
            kyc_service = KYCService()
            result = kyc_service.submit_kyc(
                user,
                id_number=data['id_number'],
                id_type=data.get('id_type', 'NATIONAL_ID'),
                country=data.get('country', 'KE')
            )
            return Response({
                'detail': 'KYC submitted successfully.',
                'verification_status': user.verification_status,
                'smile_identity_job_id': user.smile_identity_job_id
            })
        except Exception as e:
            return Response(
                {'detail': f'KYC submission failed: {str(e)}'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE
            )


class KYCWebhookView(APIView):
    """Receive verification results from Smile Identity"""
    permission_classes = [AllowAny]

    def post(self, request):
        # SECURITY: Verify the signature from Smile Identity
        if not self._verify_signature(request):
            logger.warning("Invalid Smile Identity webhook signature")
            if not settings.DEBUG:
                return Response({'detail': 'Invalid signature.'}, status=status.HTTP_401_UNAUTHORIZED)

        data = request.data
        job_id = data.get('job_id')
        status_code = data.get('ResultCode')

        try:
            user = User.objects.get(smile_identity_job_id=job_id)
            if status_code == '1012':  # Smile ID success code for Enhanced KYC
                user.verification_status = User.VerificationStatus.VERIFIED
            else:
                user.verification_status = User.VerificationStatus.REJECTED

            user.save(update_fields=['verification_status'])
            return Response({'detail': 'Webhook received.'})
        except User.DoesNotExist:
            return Response({'detail': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)

    def _verify_signature(self, request):
        """
        In production, use smile-identity-core library or HMAC SHA256
        to verify 'Smile-ID-Signature' header.
        """
        # Placeholder for actual signature verification logic
        signature = request.headers.get('Smile-ID-Signature')
        if not signature:
            return False
        # Actual verification would go here
        return True
