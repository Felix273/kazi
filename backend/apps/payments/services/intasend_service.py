import requests
from django.conf import settings
from django.utils import timezone
from apps.payments.models import Payment, WalletTransaction
import logging

logger = logging.getLogger(__name__)

INTASEND_BASE_URL = (
    'https://sandbox.intasend.com/api/v1'
    if settings.INTASEND_TEST_MODE
    else 'https://payment.intasend.com/api/v1'
)


class IntaSendService:
    """
    Handles all M-Pesa payment operations via IntaSend API.
    Docs: https://developers.intasend.com/
    """

    def __init__(self):
        self.headers = {
            'Content-Type': 'application/json',
            'X-IntaSend-Public-API-Key': settings.INTASEND_PUBLIC_KEY,
        }
        self.secret_headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {settings.INTASEND_SECRET_KEY}',
        }

    def initiate_stk_push(self, payment: Payment) -> dict:
        """
        Trigger M-Pesa STK push to employer's phone.
        Employer enters PIN on their phone to pay.
        Returns invoice tracking data.
        """
        payload = {
            'currency': 'KES',
            'amount': str(payment.amount),
            'phone_number': payment.payer_phone,
            'api_ref': str(payment.id),
            'comment': f'Kazi job payment — {payment.job.title}',
            'webhook': f'{settings.BACKEND_URL}/api/v1/payments/webhook/intasend/',
        }

        try:
            response = requests.post(
                f'{INTASEND_BASE_URL}/payment/mpesa-stk-push/',
                json=payload,
                headers=self.headers,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            # Store IntaSend invoice ID for tracking
            payment.intasend_invoice_id = data.get('invoice', {}).get('invoice_id', '')
            payment.save(update_fields=['intasend_invoice_id'])

            logger.info(f"STK push initiated for payment {payment.id}")
            return data

        except requests.RequestException as e:
            logger.error(f"IntaSend STK push failed for payment {payment.id}: {e}")
            raise

    def check_payment_status(self, invoice_id: str) -> dict:
        """Poll payment status — called by webhook or background task"""
        try:
            response = requests.get(
                f'{INTASEND_BASE_URL}/payment/mpesa-stk-push/{invoice_id}/',
                headers=self.secret_headers,
                timeout=15
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"IntaSend status check failed for invoice {invoice_id}: {e}")
            raise

    def release_to_worker(self, payment: Payment) -> dict:
        """
        Release escrowed funds to worker via M-Pesa B2C.
        Called when employer marks job as complete.
        """
        payload = {
            'currency': 'KES',
            'transactions': [{
                'account': payment.worker.phone_number,
                'amount': str(payment.worker_payout),
                'narrative': f'Kazi job payment — {payment.job.title}',
            }],
        }

        try:
            response = requests.post(
                f'{INTASEND_BASE_URL}/send-money/mpesa/',
                json=payload,
                headers=self.secret_headers,
                timeout=30
            )
            response.raise_for_status()
            data = response.json()

            payment.status = Payment.Status.RELEASED
            payment.released_at = timezone.now()
            payment.save(update_fields=['status', 'released_at'])

            # Record transaction for worker
            WalletTransaction.objects.create(
                user=payment.worker,
                transaction_type=WalletTransaction.TransactionType.CREDIT,
                amount=payment.worker_payout,
                balance_after=0,  # Update when you add wallet balance field
                description=f'Payment for: {payment.job.title}',
                reference=str(payment.id),
            )

            logger.info(f"Payment {payment.id} released to worker {payment.worker.full_name}")
            return data

        except requests.RequestException as e:
            logger.error(f"IntaSend B2C release failed for payment {payment.id}: {e}")
            raise

    def process_webhook(self, payload: dict) -> None:
        """
        Handle IntaSend webhook callbacks.
        Called when M-Pesa payment is confirmed.
        """
        invoice_id = payload.get('invoice_id')
        state = payload.get('state')  # 'COMPLETE' or 'FAILED'

        if not invoice_id:
            logger.warning("IntaSend webhook received without invoice_id")
            return

        try:
            payment = Payment.objects.get(intasend_invoice_id=invoice_id)
        except Payment.DoesNotExist:
            logger.warning(f"Payment not found for invoice {invoice_id}")
            return

        if state == 'COMPLETE':
            payment.status = Payment.Status.HELD
            payment.held_at = timezone.now()
            payment.mpesa_receipt = payload.get('receipt_number', '')
            payment.save(update_fields=['status', 'held_at', 'mpesa_receipt'])
            logger.info(f"Payment {payment.id} confirmed and held in escrow")

            # Notify employer and assigned worker
            from apps.notifications.services import NotificationService
            NotificationService().notify_payment_held(payment)

        elif state == 'FAILED':
            payment.status = Payment.Status.PENDING  # Allow retry
            payment.save(update_fields=['status'])
            logger.warning(f"Payment {payment.id} failed via webhook")
