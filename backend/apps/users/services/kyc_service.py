import requests
import json
import logging
import time
from django.conf import settings
from apps.users.models import User

logger = logging.getLogger(__name__)

class KYCService:
    def __init__(self):
        self.partner_id = settings.SMILE_IDENTITY_PARTNER_ID
        self.api_key = settings.SMILE_IDENTITY_API_KEY
        self.base_url = "https://api.smileidentity.com/v1" # Standard Smile ID API URL

    def submit_kyc(self, user: User, id_number: str, id_type: str = "NATIONAL_ID", country: str = "KE"):
        """
        Submit a KYC request to Smile Identity (Enhanced KYC).
        """
        id_photo_url = None
        if hasattr(user, 'worker_profile') and user.worker_profile.id_document:
            id_photo_url = f"{settings.BACKEND_URL}{user.worker_profile.id_document.url}"

        payload = {
            "partner_id": self.partner_id,
            "api_key": self.api_key,
            "user_id": str(user.id),
            "job_id": f"kyc_{user.id}_{int(time.time())}",
            "job_type": 5, # Enhanced KYC
            "country": country,
            "id_type": id_type,
            "id_number": id_number,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "id_photo": id_photo_url,  # URL to the uploaded ID photo
            "callback_url": f"{settings.BACKEND_URL}/api/v1/users/kyc/webhook/"
        }

        try:
            # Using a mock-like behavior if in DEBUG and keys are missing
            if settings.DEBUG and not (self.partner_id and self.api_key):
                logger.info(f"Mocking Smile ID submission for user {user.id}")
                user.smile_identity_job_id = payload["job_id"]
                user.verification_status = User.VerificationStatus.PENDING
                user.save(update_fields=['smile_identity_job_id', 'verification_status'])
                return {"status": "success", "job_id": payload["job_id"]}

            response = requests.post(f"{self.base_url}/upload", json=payload)
            response.raise_for_status()
            result = response.json()

            user.smile_identity_job_id = payload["job_id"]
            user.verification_status = User.VerificationStatus.PENDING
            user.save(update_fields=['smile_identity_job_id', 'verification_status'])

            return result
        except Exception as e:
            logger.error(f"Smile Identity submission error: {e}")
            raise
