from rest_framework import serializers
from django.contrib.auth import get_user_model
from apps.users.models import OTP, WorkerProfile, EmployerProfile, Skill
import re

User = get_user_model()


def validate_kenyan_phone(phone):
    """Normalize and validate Kenyan phone numbers to +254XXXXXXXXX format"""
    phone = phone.strip().replace(' ', '').replace('-', '')
    if phone.startswith('0'):
        phone = '+254' + phone[1:]
    elif phone.startswith('254'):
        phone = '+' + phone
    elif not phone.startswith('+254'):
        raise serializers.ValidationError('Enter a valid Kenyan phone number.')
    if not re.match(r'^\+254[17]\d{8}$', phone):
        raise serializers.ValidationError('Enter a valid Kenyan phone number.')
    return phone


class RequestOTPSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=15)

    def validate_phone_number(self, value):
        return validate_kenyan_phone(value)


class VerifyOTPSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=15)
    code = serializers.CharField(max_length=6, min_length=6)

    def validate_phone_number(self, value):
        return validate_kenyan_phone(value)


class CompleteRegistrationSerializer(serializers.Serializer):
    """Called after OTP verification if user is new"""
    first_name = serializers.CharField(max_length=50)
    last_name = serializers.CharField(max_length=50)
    user_type = serializers.ChoiceField(choices=['worker', 'employer', 'both'])

    # Worker-specific fields (optional if employer)
    skills = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        allow_empty=True
    )
    experience_years = serializers.IntegerField(required=False, min_value=0, max_value=50)
    hourly_rate = serializers.DecimalField(
        max_digits=10, decimal_places=2,
        required=False, allow_null=True
    )

    # Employer-specific fields
    company_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    is_business = serializers.BooleanField(required=False, default=False)


class SkillSerializer(serializers.ModelSerializer):
    class Meta:
        model = Skill
        fields = ['id', 'name', 'category', 'icon']


class WorkerProfileSerializer(serializers.ModelSerializer):
    skills = SkillSerializer(many=True, read_only=True)

    class Meta:
        model = WorkerProfile
        fields = ['is_available', 'hourly_rate', 'skills', 'experience_years', 'is_subscribed']


class EmployerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployerProfile
        fields = ['company_name', 'company_description', 'is_business']


class UserSerializer(serializers.ModelSerializer):
    worker_profile = WorkerProfileSerializer(read_only=True)
    employer_profile = EmployerProfileSerializer(read_only=True)
    full_name = serializers.ReadOnlyField()
    is_verified = serializers.ReadOnlyField()

    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'email', 'first_name', 'last_name',
            'full_name', 'user_type', 'profile_photo', 'bio',
            'location_name', 'verification_status', 'is_verified',
            'average_rating', 'total_reviews', 'total_jobs_completed',
            'is_online', 'date_joined', 'worker_profile', 'employer_profile',
        ]
        read_only_fields = [
            'id', 'phone_number', 'verification_status',
            'average_rating', 'total_reviews', 'total_jobs_completed', 'date_joined',
        ]


class UpdateProfileSerializer(serializers.ModelSerializer):
    """For updating user profile details"""
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'bio', 'profile_photo', 'location_name']


class UpdateLocationSerializer(serializers.Serializer):
    """Update user's current GPS location"""
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)
    location_name = serializers.CharField(max_length=200, required=False, allow_blank=True)


class UpdateFCMTokenSerializer(serializers.Serializer):
    fcm_token = serializers.CharField(max_length=500)


class SubmitKYCSerializer(serializers.Serializer):
    id_image = serializers.CharField(help_text='Base64 encoded ID image')
    selfie_image = serializers.CharField(help_text='Base64 encoded selfie image')
    id_type = serializers.ChoiceField(choices=['national_id', 'passport', 'driving_license'], default='national_id')

    def validate_id_image(self, value):
        if not value.startswith('data:image'):
            raise serializers.ValidationError('Invalid image format. Expected base64 data URL.')
        return value

    def validate_selfie_image(self, value):
        if not value.startswith('data:image'):
            raise serializers.ValidationError('Invalid image format. Expected base64 data URL.')
        return value


class WorkerProfileUpdateSerializer(serializers.ModelSerializer):
    skills = serializers.ListField(
        child=serializers.IntegerField(),
        required=False,
        write_only=True
    )

    class Meta:
        model = WorkerProfile
        fields = ['is_available', 'hourly_rate', 'experience_years', 'skills']

    def update(self, instance, validated_data):
        skills_ids = validated_data.pop('skills', None)
        if skills_ids is not None:
            instance.skills.set(skills_ids)
        return super().update(instance, validated_data)
