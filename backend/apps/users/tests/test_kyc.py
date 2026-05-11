from django.test import TestCase
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.users.models import User
from unittest.mock import patch

class KYCTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            phone_number='+254712345678',
            first_name='John',
            last_name='Doe'
        )
        self.client.force_authenticate(user=self.user)

    @patch('apps.users.services.kyc_service.KYCService.submit_kyc')
    def test_kyc_submit(self, mock_submit):
        mock_submit.return_value = {"status": "success", "job_id": "test_job"}
        url = reverse('kyc-submit')
        data = {
            'id_number': '12345678',
            'id_type': 'NATIONAL_ID',
            'country': 'KE'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.national_id_number, '12345678')

    def test_kyc_webhook(self):
        self.user.smile_identity_job_id = 'test_job'
        self.user.verification_status = User.VerificationStatus.PENDING
        self.user.save()

        url = reverse('kyc-webhook')
        data = {
            'job_id': 'test_job',
            'ResultCode': '1012'
        }
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.verification_status, User.VerificationStatus.VERIFIED)
