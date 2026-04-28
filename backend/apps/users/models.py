from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.contrib.gis.db import models
from django.utils import timezone
import uuid


class UserManager(BaseUserManager):
    def create_user(self, phone_number, **extra_fields):
        if not phone_number:
            raise ValueError('Phone number is required')
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user


class User(AbstractBaseUser, PermissionsMixin):
    class UserType(models.TextChoices):
        WORKER = 'worker', 'Worker'
        EMPLOYER = 'employer', 'Employer'
        BOTH = 'both', 'Both'

    class VerificationStatus(models.TextChoices):
        UNVERIFIED = 'unverified', 'Unverified'
        PENDING = 'pending', 'Pending'
        VERIFIED = 'verified', 'Verified'
        REJECTED = 'rejected', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    phone_number = models.CharField(max_length=15, unique=True)
    email = models.EmailField(blank=True, null=True)
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    user_type = models.CharField(max_length=10, choices=UserType.choices, default=UserType.WORKER)
    profile_photo = models.ImageField(upload_to='profile_photos/', blank=True, null=True)
    bio = models.TextField(blank=True)
    location = models.PointField(geography=True, blank=True, null=True)  # PostGIS point
    location_name = models.CharField(max_length=200, blank=True)  # Human readable e.g. "Westlands, Nairobi"

    # Verification
    verification_status = models.CharField(
        max_length=20,
        choices=VerificationStatus.choices,
        default=VerificationStatus.UNVERIFIED
    )
    national_id_number = models.CharField(max_length=20, blank=True)
    smile_identity_job_id = models.CharField(max_length=100, blank=True)  # KYC tracking

    # Stats
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    total_reviews = models.IntegerField(default=0)
    total_jobs_completed = models.IntegerField(default=0)

    # Device token for push notifications
    fcm_token = models.CharField(max_length=500, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_online = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)
    last_seen = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    objects = UserManager()

    class Meta:
        db_table = 'users'

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.phone_number})"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    @property
    def is_verified(self):
        return self.verification_status == self.VerificationStatus.VERIFIED


class OTP(models.Model):
    """One-time passwords for phone authentication"""
    phone_number = models.CharField(max_length=15)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    attempts = models.IntegerField(default=0)

    class Meta:
        db_table = 'otps'

    def __str__(self):
        return f"OTP for {self.phone_number}"


class WorkerProfile(models.Model):
    """Extended profile for workers"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='worker_profile')
    is_available = models.BooleanField(default=True)
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    skills = models.ManyToManyField('Skill', blank=True)
    experience_years = models.IntegerField(default=0)
    id_document = models.ImageField(upload_to='id_documents/', blank=True, null=True)

    # Subscription
    is_subscribed = models.BooleanField(default=False)
    subscription_expires = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'worker_profiles'

    def __str__(self):
        return f"Worker: {self.user.full_name}"


class EmployerProfile(models.Model):
    """Extended profile for employers"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='employer_profile')
    company_name = models.CharField(max_length=200, blank=True)
    company_description = models.TextField(blank=True)
    is_business = models.BooleanField(default=False)  # individual vs business

    class Meta:
        db_table = 'employer_profiles'

    def __str__(self):
        return f"Employer: {self.user.full_name}"


class Skill(models.Model):
    """Skill categories workers can list"""
    class Category(models.TextChoices):
        MANUAL = 'manual', 'Manual Labour'
        PROFESSIONAL = 'professional', 'Professional Services'
        ERRANDS = 'errands', 'Errands & Delivery'
        DIGITAL = 'digital', 'Digital Work'

    name = models.CharField(max_length=100, unique=True)
    category = models.CharField(max_length=20, choices=Category.choices)
    icon = models.CharField(max_length=50, blank=True)  # icon name for flutter

    class Meta:
        db_table = 'skills'

    def __str__(self):
        return self.name
