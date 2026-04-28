from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from apps.payments.models import Payment
from apps.payments.services.intasend_service import IntaSendService
import logging

logger = logging.getLogger(__name__)


class PaymentStatusView(APIView):
    def get(self, request, job_id):
        try:
            payment = Payment.objects.get(job_id=job_id, employer=request.user)
        except Payment.DoesNotExist:
            return Response({'detail': 'Payment not found.'}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            'status': payment.status,
            'amount': str(payment.amount),
            'platform_fee': str(payment.platform_fee),
            'worker_payout': str(payment.worker_payout),
            'mpesa_receipt': payment.mpesa_receipt,
            'held_at': payment.held_at,
            'released_at': payment.released_at,
        })


class IntaSendWebhookView(APIView):
    """
    IntaSend posts payment confirmations here.
    Must be publicly accessible (no auth).
    Verify signature in production.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        payload = request.data
        logger.info(f"IntaSend webhook received: {payload}")

        try:
            IntaSendService().process_webhook(payload)
        except Exception as e:
            logger.error(f"Webhook processing error: {e}")
            return Response({'detail': 'Webhook processing failed.'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({'detail': 'OK'})
