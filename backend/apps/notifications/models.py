from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Notification(models.Model):
    class NotificationType(models.TextChoices):
        JOB_ALERT = 'job_alert', 'New Job Near You'
        APPLICATION_RECEIVED = 'application_received', 'New Application'
        APPLICATION_ACCEPTED = 'application_accepted', 'Application Accepted'
        JOB_STARTED = 'job_started', 'Job Started'
        JOB_COMPLETED = 'job_completed', 'Job Completed'
        JOB_CANCELLED = 'job_cancelled', 'Job Cancelled'
        JOB_DISPUTED = 'job_disputed', 'Job Disputed'
        PAYMENT_HELD = 'payment_held', 'Payment Secured'
        PAYMENT_RELEASED = 'payment_released', 'Payment Released'
        NEW_MESSAGE = 'new_message', 'New Message'
        REVIEW_RECEIVED = 'review_received', 'New Review'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=30, choices=NotificationType.choices)
    title = models.CharField(max_length=200)
    body = models.TextField()
    data = models.JSONField(default=dict)  # e.g. {'job_id': '...', 'room_id': '...'}
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.notification_type} → {self.user.full_name}"
