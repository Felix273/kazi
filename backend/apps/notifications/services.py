import requests
import json
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from apps.notifications.models import Notification
import logging

logger = logging.getLogger(__name__)


class NotificationService:
    """
    Sends notifications via two channels simultaneously:
    1. WebSocket (instant, if user is online)
    2. FCM push notification (if user has a device token)
    """

    def _send(self, user, notification_type: str, title: str, body: str, data: dict = None):
        data = data or {}

        # Save to DB
        notif = Notification.objects.create(
            user=user,
            notification_type=notification_type,
            title=title,
            body=body,
            data=data,
        )

        # WebSocket push (real-time if online)
        self._push_websocket(user, notification_type, title, body, data)

        # FCM push (background/offline)
        if user.fcm_token:
            self._push_fcm(user.fcm_token, title, body, data)

        return notif

    def _push_websocket(self, user, notification_type, title, body, data):
        try:
            channel_layer = get_channel_layer()
            async_to_sync(channel_layer.group_send)(
                f'notifications_{user.id}',
                {
                    'type': 'notify',
                    'notification_type': notification_type,
                    'title': title,
                    'body': body,
                    'data': data,
                }
            )
        except Exception as e:
            logger.warning(f"WebSocket push failed for user {user.id}: {e}")

    def _push_fcm(self, fcm_token: str, title: str, body: str, data: dict):
        try:
            payload = {
                'to': fcm_token,
                'notification': {'title': title, 'body': body, 'sound': 'default'},
                'data': {k: str(v) for k, v in data.items()},
                'priority': 'high',
            }
            response = requests.post(
                'https://fcm.googleapis.com/fcm/send',
                headers={
                    'Authorization': f'key={settings.FIREBASE_SERVER_KEY}',
                    'Content-Type': 'application/json',
                },
                json=payload,
                timeout=10,
            )
            if response.status_code != 200:
                logger.warning(f"FCM push failed: {response.text}")
        except Exception as e:
            logger.warning(f"FCM push error: {e}")

    # ── Public methods called by views/services ────────────────────────────────

    def notify_new_job(self, worker, job):
        self._send(
            user=worker,
            notification_type=Notification.NotificationType.JOB_ALERT,
            title='New job near you 📍',
            body=f'{job.title} — KES {job.budget:.0f} in {job.location_address}',
            data={'job_id': str(job.id), 'screen': 'job_detail'},
        )

    def notify_application_received(self, employer, job, worker):
        self._send(
            user=employer,
            notification_type=Notification.NotificationType.APPLICATION_RECEIVED,
            title='New application received',
            body=f'{worker.full_name} applied for: {job.title}',
            data={'job_id': str(job.id), 'screen': 'job_applications'},
        )

    def notify_application_accepted(self, worker, job):
        self._send(
            user=worker,
            notification_type=Notification.NotificationType.APPLICATION_ACCEPTED,
            title='You got the job! 🎉',
            body=f'Your application for "{job.title}" was accepted.',
            data={'job_id': str(job.id), 'screen': 'job_detail'},
        )

    def notify_payment_held(self, payment):
        self._send(
            user=payment.worker,
            notification_type=Notification.NotificationType.PAYMENT_HELD,
            title='Payment secured 🔒',
            body=f'KES {payment.worker_payout:.0f} is held in escrow for: {payment.job.title}',
            data={'job_id': str(payment.job.id), 'screen': 'job_detail'},
        )

    def notify_payment_released(self, payment):
        self._send(
            user=payment.worker,
            notification_type=Notification.NotificationType.PAYMENT_RELEASED,
            title='Payment sent to M-Pesa 💸',
            body=f'KES {payment.worker_payout:.0f} has been sent to your M-Pesa.',
            data={'job_id': str(payment.job.id), 'screen': 'earnings'},
        )

    def notify_new_message(self, recipient, sender, job):
        self._send(
            user=recipient,
            notification_type=Notification.NotificationType.NEW_MESSAGE,
            title=f'Message from {sender.full_name}',
            body=f'New message about: {job.title}',
            data={'room_id': str(job.chat_room.id), 'screen': 'chat'},
        )

    def notify_job_started(self, employer, job):
        self._send(
            user=employer,
            notification_type=Notification.NotificationType.JOB_STARTED,
            title='Job started',
            body=f'{job.assigned_worker.full_name} started working on "{job.title}".',
            data={'job_id': str(job.id), 'screen': 'job_detail'},
        )

    def notify_job_cancelled(self, employer, job):
        recipient = employer if job.employer == employer else job.assigned_worker
        self._send(
            user=recipient,
            notification_type=Notification.NotificationType.JOB_CANCELLED,
            title='Job cancelled',
            body=f'"{job.title}" has been cancelled.',
            data={'job_id': str(job.id), 'screen': 'job_detail'},
        )

    def notify_job_disputed(self, employer, job):
        recipient = employer if job.employer == employer else job.assigned_worker
        self._send(
            user=recipient,
            notification_type=Notification.NotificationType.JOB_DISPUTED,
            title='Job disputed',
            body=f'"{job.title}" has been marked as disputed.',
            data={'job_id': str(job.id), 'screen': 'job_detail'},
        )
