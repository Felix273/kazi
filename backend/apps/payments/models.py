from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Payment(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'           # STK push sent, awaiting M-Pesa confirmation
        HELD = 'held', 'Held in Escrow'          # Money received, held until job done
        RELEASED = 'released', 'Released'         # Job complete, released to worker
        REFUNDED = 'refunded', 'Refunded'         # Job cancelled, returned to employer
        DISPUTED = 'disputed', 'Disputed'         # Under review

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    job = models.OneToOneField('jobs.Job', on_delete=models.CASCADE, related_name='payment')
    employer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payments_made')
    worker = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True, related_name='payments_received'
    )

    amount = models.DecimalField(max_digits=10, decimal_places=2)
    platform_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    worker_payout = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)

    # IntaSend tracking
    intasend_invoice_id = models.CharField(max_length=100, blank=True)
    intasend_tracking_id = models.CharField(max_length=100, blank=True)
    mpesa_receipt = models.CharField(max_length=100, blank=True)

    # Employer's M-Pesa number (may differ from account phone)
    payer_phone = models.CharField(max_length=15)

    created_at = models.DateTimeField(auto_now_add=True)
    held_at = models.DateTimeField(null=True, blank=True)
    released_at = models.DateTimeField(null=True, blank=True)

    PLATFORM_FEE_PERCENTAGE = 10  # 10% commission

    class Meta:
        db_table = 'payments'

    def __str__(self):
        return f"Payment {self.id} — KES {self.amount} ({self.status})"

    def calculate_fees(self):
        """Calculate platform fee and worker payout"""
        self.platform_fee = (self.amount * self.PLATFORM_FEE_PERCENTAGE) / 100
        self.worker_payout = self.amount - self.platform_fee
        return self.worker_payout


class Withdrawal(models.Model):
    """Worker withdrawing earnings to M-Pesa"""
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        PROCESSING = 'processing', 'Processing'
        COMPLETED = 'completed', 'Completed'
        FAILED = 'failed', 'Failed'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    worker = models.ForeignKey(User, on_delete=models.CASCADE, related_name='withdrawals')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    phone_number = models.CharField(max_length=15)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    intasend_id = models.CharField(max_length=100, blank=True)
    mpesa_receipt = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'withdrawals'


class WalletTransaction(models.Model):
    """Ledger of all money movements per user"""
    class TransactionType(models.TextChoices):
        CREDIT = 'credit', 'Credit'
        DEBIT = 'debit', 'Debit'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=10, choices=TransactionType.choices)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    balance_after = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.CharField(max_length=200)
    reference = models.CharField(max_length=100, blank=True)  # payment/withdrawal ID
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'wallet_transactions'
        ordering = ['-created_at']
