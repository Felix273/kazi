from rest_framework import serializers
from apps.jobs.models import Job, JobApplication, Review
from apps.users.serializers import SkillSerializer


class JobSerializer(serializers.ModelSerializer):
    employer_name = serializers.SerializerMethodField()
    employer_photo = serializers.SerializerMethodField()
    application_count = serializers.SerializerMethodField()
    required_skills = SkillSerializer(many=True, read_only=True)
    duration_display = serializers.SerializerMethodField()
    budget_display = serializers.SerializerMethodField()

    class Meta:
        model = Job
        fields = [
            'id', 'title', 'description', 'category', 'status',
            'budget', 'budget_display', 'is_negotiable',
            'duration_value', 'duration_unit', 'duration_display',
            'location_address', 'search_radius_km',
            'employer_id', 'employer_name', 'employer_photo',
            'assigned_worker_id', 'application_count',
            'required_skills', 'created_at', 'starts_at',
        ]

    def get_employer_name(self, obj):
        return obj.employer.full_name

    def get_employer_photo(self, obj):
        if obj.employer.profile_photo:
            return obj.employer.profile_photo.url
        return None

    def get_application_count(self, obj):
        return obj.applications.filter(status='pending').count()

    def get_duration_display(self, obj):
        unit = obj.duration_unit if obj.duration_value > 1 else obj.duration_unit.rstrip('s')
        return f'{obj.duration_value} {unit}'

    def get_budget_display(self, obj):
        return f'KES {obj.budget:,.0f}'


class JobCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=200)
    description = serializers.CharField(min_length=20)
    category = serializers.ChoiceField(choices=['manual', 'professional', 'errands', 'digital'])
    budget = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=100)
    is_negotiable = serializers.BooleanField(default=False)
    duration_value = serializers.IntegerField(min_value=1)
    duration_unit = serializers.ChoiceField(choices=['hours', 'days'])
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    location_address = serializers.CharField(max_length=300)
    search_radius_km = serializers.IntegerField(default=10, min_value=1, max_value=50)
    required_skill_ids = serializers.ListField(
        child=serializers.IntegerField(), required=False
    )


class JobApplicationSerializer(serializers.ModelSerializer):
    worker_id = serializers.SerializerMethodField()
    worker_name = serializers.SerializerMethodField()
    worker_photo = serializers.SerializerMethodField()
    worker_rating = serializers.SerializerMethodField()
    worker_total_jobs = serializers.SerializerMethodField()
    worker_is_verified = serializers.SerializerMethodField()

    class Meta:
        model = JobApplication
        fields = [
            'id', 'job', 'status', 'cover_note', 'proposed_rate', 'created_at',
            'worker_id', 'worker_name', 'worker_photo',
            'worker_rating', 'worker_total_jobs', 'worker_is_verified',
        ]

    def get_worker_id(self, obj): return str(obj.worker.id)
    def get_worker_name(self, obj): return obj.worker.full_name
    def get_worker_photo(self, obj):
        return obj.worker.profile_photo.url if obj.worker.profile_photo else None
    def get_worker_rating(self, obj): return float(obj.worker.average_rating)
    def get_worker_total_jobs(self, obj): return obj.worker.total_jobs_completed
    def get_worker_is_verified(self, obj): return obj.worker.is_verified


class ReviewSerializer(serializers.ModelSerializer):
    reviewer_name = serializers.SerializerMethodField()
    reviewer_photo = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ['id', 'job', 'rating', 'comment', 'created_at',
                  'reviewer_name', 'reviewer_photo']

    def get_reviewer_name(self, obj): return obj.reviewer.full_name
    def get_reviewer_photo(self, obj):
        return obj.reviewer.profile_photo.url if obj.reviewer.profile_photo else None
