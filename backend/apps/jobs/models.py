from django.contrib.gis.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Job(models.Model):
    class Status(models.TextChoices):
        OPEN = 'open', 'Open'
        ASSIGNED = 'assigned', 'Assigned'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        DISPUTED = 'disputed', 'Disputed'

    class Category(models.TextChoices):
        MANUAL = 'manual', 'Manual Labour'
        PROFESSIONAL = 'professional', 'Professional Services'
        ERRANDS = 'errands', 'Errands & Delivery'
        DIGITAL = 'digital', 'Digital Work'

    class DurationUnit(models.TextChoices):
        HOURS = 'hours', 'Hours'
        DAYS = 'days', 'Days'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posted_jobs')
    assigned_worker = models.ForeignKey(
        User, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='assigned_jobs'
    )

    title = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=20, choices=Category.choices)
    required_skills = models.ManyToManyField('users.Skill', blank=True)

    # Location
    location = models.PointField(geography=True)
    location_address = models.CharField(max_length=300)

    # Budget
    budget = models.DecimalField(max_digits=10, decimal_places=2)
    is_negotiable = models.BooleanField(default=False)

    # Duration
    duration_value = models.IntegerField()
    duration_unit = models.CharField(max_length=10, choices=DurationUnit.choices, default=DurationUnit.HOURS)

    # Status
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    # Search radius — how far to broadcast to workers
    search_radius_km = models.IntegerField(default=10)

    # How many workers have been notified
    notified_workers_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'jobs'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} — {self.employer.full_name}"


class JobApplication(models.Model):
    """Workers express interest / apply for a job"""
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        ACCEPTED = 'accepted', 'Accepted'
        DECLINED = 'declined', 'Declined'
        WITHDRAWN = 'withdrawn', 'Withdrawn'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='applications')
    worker = models.ForeignKey(User, on_delete=models.CASCADE, related_name='job_applications')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    cover_note = models.TextField(blank=True)
    proposed_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'job_applications'
        unique_together = ['job', 'worker']

    def __str__(self):
        return f"{self.worker.full_name} → {self.job.title}"


class Review(models.Model):
    """Post-job ratings for both workers and employers"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='reviews')
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_given')
    reviewee = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_received')
    rating = models.IntegerField()  # 1-5
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reviews'
        unique_together = ['job', 'reviewer']

    def __str__(self):
        return f"{self.reviewer.full_name} → {self.reviewee.full_name}: {self.rating}★"
