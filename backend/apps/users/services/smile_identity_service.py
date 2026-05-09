import requests
import base64
import logging
from django.conf import settings
from django.core.files.base import ContentFile

logger = logging.getLogger(__name__)


class SmileIdentityService:
    BASE_URL = "https://api.smileidentity.com/v1"

    def __init__(self):
        self.partner_id = settings.SMILE_IDENTITY.get('PARTNER_ID')
        self.api_key = settings.SMILE_IDENTITY.get('API_KEY')
        self.auth_token = settings.SMILE_IDENTITY.get('AUTH_TOKEN')

    def _get_headers(self):
        return {
            'Accept': 'application/json',
            'Authorization': f'Bearer {self.auth_token}',
        }

    def submit_verification(self, user, id_image_base64, selfie_image_base64, id_type='national_id'):
        """Submit ID verification to Smile Identity"""
        try:
            # Extract base64 data (remove data:image/... prefix)
            if 'base64,' in id_image_base64:
                id_image_data = id_image_base64.split('base64,')[1]
            else:
                id_image_data = id_image_base64

            if 'base64,' in selfie_image_base64:
                selfie_image_data = selfie_image_base64.split('base64,')[1]
            else:
                selfie_image_data = selfie_image_base64

            payload = {
                'partner_id': self.partner_id,
                'id_type': id_type,
                'id_image': id_image_data,
                'selfie_image': selfie_image_data,
                'user_id': str(user.id),
                'user': {
                    'name': user.get_full_name(),
                    'phone': user.phone_number,
                }
            }

            response = requests.post(
                f'{self.BASE_URL}/verify',
                json=payload,
                headers=self._get_headers(),
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                job_id = result.get('job_id')
                user.smile_identity_job_id = job_id
                user.verification_status = 'pending'
                user.save(update_fields=['smile_identity_job_id', 'verification_status'])
                logger.info(f"KYC submitted for user {user.id}, job_id: {job_id}")
                return {'success': True, 'job_id': job_id}

            logger.error(f"Smile Identity submit failed: {response.text}")
            return {'success': False, 'error': 'Verification submission failed'}

        except Exception as e:
            logger.exception(f"Smile Identity error: {e}")
            return {'success': False, 'error': str(e)}

    def check_verification_status(self, user):
        """Check verification status from Smile Identity"""
        if not user.smile_identity_job_id:
            return {'success': False, 'error': 'No verification job found'}

        try:
            response = requests.get(
                f'{self.BASE_URL}/verification/{user.smile_identity_job_id}',
                headers=self._get_headers(),
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()
                status = result.get('status', '').lower()

                if status == 'success':
                    user.verification_status = 'verified'
                    user.save(update_fields=['verification_status'])
                elif status == 'failed':
                    user.verification_status = 'rejected'
                    user.save(update_fields=['verification_status'])

                return {'success': True, 'status': status, 'data': result}

            return {'success': False, 'error': 'Failed to check status'}

        except Exception as e:
            logger.exception(f"Smile Identity status check error: {e}")
            return {'success': False, 'error': str(e)}

    def process_webhook(self, data):
        """Process webhook callback from Smile Identity"""
        try:
            job_id = data.get('job_id')
            status = data.get('status', '').lower()

            from apps.users.models import User
            user = User.objects.filter(smile_identity_job_id=job_id).first()

            if user:
                if status == 'success':
                    user.verification_status = 'verified'
                elif status in ['failed', 'rejected']:
                    user.verification_status = 'rejected'
                user.save(update_fields=['verification_status'])

                return {'success': True, 'user_id': str(user.id)}

            return {'success': False, 'error': 'User not found'}

        except Exception as e:
            logger.exception(f"Smile Identity webhook error: {e}")
            return {'success': False, 'error': str(e)}