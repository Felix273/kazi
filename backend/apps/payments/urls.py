from django.urls import path
from apps.payments.views import PaymentStatusView, IntaSendWebhookView, InitiatePaymentView, WithdrawalCreateView

urlpatterns = [
    path('<uuid:job_id>/status/', PaymentStatusView.as_view(), name='payment-status'),
    path('initiate/', InitiatePaymentView.as_view(), name='initiate-payment'),
    path('withdraw/', WithdrawalCreateView.as_view(), name='initiate-withdrawal'),
    path('webhook/intasend/', IntaSendWebhookView.as_view(), name='intasend-webhook'),
]
