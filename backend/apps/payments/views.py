from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.db import transaction

from apps.payments.models import Payment, Withdrawal
from apps.payments.services.intasend_service import IntaSendService
from apps.jobs.models import Job
from apps.notifications.services import NotificationService
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


class InitiatePaymentView(APIView):
    """Employer triggers M-Pesa STK push after accepting a worker"""
    def post(self, request):
        job_id = request.data.get('job_id')
        payer_phone = request.data.get('payer_phone', request.user.phone_number)

        try:
            job = Job.objects.get(id=job_id, employer=request.user, status='assigned')
            payment = job.payment
        except (Job.DoesNotExist, Payment.DoesNotExist):
            return Response({'detail': 'Job or payment not found.'},
                            status=status.HTTP_404_NOT_FOUND)

        payment.payer_phone = payer_phone
        payment.save(update_fields=['payer_phone'])

        try:
            result = IntaSendService().initiate_stk_push(payment)
            return Response({'detail': 'STK push sent. Check your phone.', 'data': result})
        except Exception:
            return Response({'detail': 'Payment initiation failed. Try again.'},
                            status=status.HTTP_503_SERVICE_UNAVAILABLE)


class WithdrawalCreateView(APIView):
    """Worker requests withdrawal to M-Pesa"""
    def post(self, request):
        amount = request.data.get('amount')
        phone = request.data.get('phone_number')

        if not amount or float(amount) <= 0:
            return Response({'detail': 'Invalid amount.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                withdrawal = Withdrawal.objects.create(
                    worker=request.user,
                    amount=amount,
                    phone_number=phone or request.user.phone_number,
                    status=Withdrawal.Status.PENDING,
                )
                result = IntaSendService().initiate_withdrawal(withdrawal)
                if result.get('success'):
                    return Response({'detail': 'Withdrawal initiated.', 'withdrawal_id': str(withdrawal.id)})
                return Response({'detail': result.get('error', 'Withdrawal failed.')},
                                status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.exception(f"Withdrawal error: {e}")
            return Response({'detail': 'Withdrawal failed.'},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
