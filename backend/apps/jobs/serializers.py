from rest_framework import serializers
from apps.jobs.models import Job, JobApplication, Review
from apps.users.serializers import SkillSerializer


class JobSerializer(serializers.ModelSerializer):
    employer_detail = serializers.SerializerMethodField()
    application_count = serializers.SerializerMethodField()
    has_applied = serializers.SerializerMethodField()
    required_skills = SkillSerializer(many=True, read_only=True)
    duration_display = serializers.SerializerMethodField()
    budget_display = serializers.SerializerMethodField()
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = Job
        fields = [
            'id', 'title', 'description', 'category', 'category_display', 'status',
            'budget', 'budget_display', 'is_negotiable',
            'duration_value', 'duration_unit', 'duration_display',
            'location_address', 'search_radius_km',
            'employer_id', 'employer_detail',
            'assigned_worker_id', 'application_count', 'has_applied',
            'required_skills', 'created_at', 'starts_at',
        ]

    def get_employer_detail(self, obj):
        return {
            'id': str(obj.employer.id),
            'first_name': obj.employer.first_name,
            'last_name': obj.employer.last_name,
            'full_name': obj.employer.full_name,
            'profile_photo': obj.employer.profile_photo.url if obj.employer.profile_photo else None,
            'average_rating': float(obj.employer.average_rating),
            'total_jobs_posted': obj.employer.posted_jobs.count(),
            'is_verified': obj.employer.is_verified,
        }

    def get_has_applied(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.applications.filter(worker=request.user).exists()
        return False

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
    worker_detail = serializers.SerializerMethodField()

    class Meta:
        model = JobApplication
        fields = [
            'id', 'job', 'status', 'cover_note', 'proposed_rate', 'created_at',
            'worker_detail',
        ]

    def get_worker_detail(self, obj):
        return {
            'id': str(obj.worker.id),
            'first_name': obj.worker.first_name,
            'last_name': obj.worker.last_name,
            'full_name': obj.worker.full_name,
            'profile_photo': obj.worker.profile_photo.url if obj.worker.profile_photo else None,
            'average_rating': float(obj.worker.average_rating),
            'total_jobs_completed': obj.worker.total_jobs_completed,
            'is_verified': obj.worker.is_verified,
        }


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
