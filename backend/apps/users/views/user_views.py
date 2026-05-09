from rest_framework.views import APIView
from rest_framework.generics import RetrieveUpdateAPIView, ListAPIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.conf import settings
import logging

from apps.users.models import User, Skill, WorkerProfile
from apps.users.serializers import (
    UserSerializer, UpdateProfileSerializer,
    UpdateLocationSerializer, UpdateFCMTokenSerializer, SkillSerializer,
    SubmitKYCSerializer, WorkerProfileUpdateSerializer
)
from apps.users.services.smile_identity_service import SmileIdentityService

logger = logging.getLogger(__name__)


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


class SubmitKYCView(APIView):
    """Submit ID verification to Smile Identity"""

    def post(self, request):
        serializer = SubmitKYCSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        if request.user.verification_status == 'verified':
            return Response({'detail': 'Already verified.'}, status=status.HTTP_400_BAD_REQUEST)

        service = SmileIdentityService()
        result = service.submit_verification(
            request.user,
            serializer.validated_data['id_image'],
            serializer.validated_data['selfie_image'],
            serializer.validated_data['id_type']
        )

        if result['success']:
            return Response({'detail': 'Verification submitted. Results will be sent shortly.'})
        return Response({'detail': result.get('error', 'Submission failed')}, status=status.HTTP_400_BAD_REQUEST)


class KYCStatusView(APIView):
    """Check KYC verification status"""

    def get(self, request):
        service = SmileIdentityService()
        result = service.check_verification_status(request.user)

        if result['success']:
            return Response({
                'status': request.user.verification_status,
                'job_id': request.user.smile_identity_job_id
            })
        return Response({'detail': result.get('error', 'Status check failed')}, status=status.HTTP_400_BAD_REQUEST)


class WorkerProfileUpdateView(APIView):
    """Update worker profile (skills, hourly rate, availability, etc.)"""

    def put(self, request):
        if request.user.user_type != 'worker':
            return Response({'detail': 'Only workers can update this profile.'}, status=status.HTTP_403_FORBIDDEN)

        profile, _ = WorkerProfile.objects.get_or_create(user=request.user)
        serializer = WorkerProfileUpdateSerializer(profile, data=request.data)

        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SmileIdentityWebhookView(APIView):
    """Public webhook endpoint for Smile Identity callbacks"""

    authentication_classes = []
    permission_classes = []

    def post(self, request):
        signature = request.headers.get('X-Smile-Signature')
        if not signature or signature != settings.SMILE_IDENTITY.get('WEBHOOK_SECRET'):
            return Response(status=status.HTTP_403_FORBIDDEN)

        service = SmileIdentityService()
        result = service.process_webhook(request.data)
        return Response({'success': result['success']})
