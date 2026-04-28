from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone
from django.conf import settings
from datetime import timedelta
import random
import logging

from apps.users.models import User, OTP, WorkerProfile, EmployerProfile, Skill
from apps.users.serializers import (
    RequestOTPSerializer, VerifyOTPSerializer,
    CompleteRegistrationSerializer, UserSerializer
)
from apps.users.services.sms_service import SMSService

logger = logging.getLogger(__name__)


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        phone_number = serializer.validated_data['phone_number']

        # Invalidate existing OTPs for this number
        OTP.objects.filter(phone_number=phone_number, is_used=False).update(is_used=True)

        # Generate new OTP
        code = ''.join([str(random.randint(0, 9)) for _ in range(settings.OTP_LENGTH)])
        OTP.objects.create(phone_number=phone_number, code=code)

        # Send SMS
        sms_service = SMSService()
        message = f"Your Kazi verification code is: {code}. Valid for {settings.OTP_EXPIRY_MINUTES} minutes. Do not share this code."

        try:
            sms_service.send_sms(phone_number, message)
        except Exception as e:
            logger.error(f"SMS send failed for {phone_number}: {e}")
            # Still return success in dev (don't reveal SMS failures to client)
            if not settings.DEBUG:
                return Response(
                    {'detail': 'Failed to send SMS. Please try again.'},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE
                )

        # In debug mode, return the code for testing
        response_data = {'detail': 'OTP sent successfully.', 'phone_number': phone_number}
        if settings.DEBUG:
            response_data['debug_code'] = code

        return Response(response_data, status=status.HTTP_200_OK)


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        phone_number = serializer.validated_data['phone_number']
        code = serializer.validated_data['code']

        # Find valid OTP
        expiry_time = timezone.now() - timedelta(minutes=settings.OTP_EXPIRY_MINUTES)
        otp = OTP.objects.filter(
            phone_number=phone_number,
            code=code,
            is_used=False,
            created_at__gte=expiry_time
        ).first()

        if not otp:
            # Increment attempts on most recent OTP
            latest_otp = OTP.objects.filter(
                phone_number=phone_number, is_used=False
            ).first()
            if latest_otp:
                latest_otp.attempts += 1
                latest_otp.save()
            return Response(
                {'detail': 'Invalid or expired OTP.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Mark OTP as used
        otp.is_used = True
        otp.save()

        # Get or create user
        user, created = User.objects.get_or_create(phone_number=phone_number)

        tokens = get_tokens_for_user(user)

        return Response({
            'tokens': tokens,
            'user': UserSerializer(user).data,
            'is_new_user': created,
        }, status=status.HTTP_200_OK)


class CompleteRegistrationView(APIView):
    """Called after first-time OTP verification to complete profile setup"""

    def post(self, request):
        serializer = CompleteRegistrationSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        user = request.user

        # Update user base fields
        user.first_name = data['first_name']
        user.last_name = data['last_name']
        user.user_type = data['user_type']
        user.save()

        # Create worker profile if needed
        if data['user_type'] in ['worker', 'both']:
            worker_profile, _ = WorkerProfile.objects.get_or_create(user=user)
            if 'experience_years' in data:
                worker_profile.experience_years = data['experience_years']
            if 'hourly_rate' in data:
                worker_profile.hourly_rate = data['hourly_rate']
            if 'skills' in data and data['skills']:
                skills = Skill.objects.filter(id__in=data['skills'])
                worker_profile.skills.set(skills)
            worker_profile.save()

        # Create employer profile if needed
        if data['user_type'] in ['employer', 'both']:
            employer_profile, _ = EmployerProfile.objects.get_or_create(user=user)
            employer_profile.company_name = data.get('company_name', '')
            employer_profile.is_business = data.get('is_business', False)
            employer_profile.save()

        return Response({
            'detail': 'Profile completed successfully.',
            'user': UserSerializer(user).data,
        }, status=status.HTTP_200_OK)


class RefreshTokenView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            return Response({
                'access': str(token.access_token),
                'refresh': str(token),
            })
        except Exception:
            return Response(
                {'detail': 'Invalid refresh token.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
