from django.urls import path
from apps.payments.views import PaymentStatusView, IntaSendWebhookView

urlpatterns = [
    path('<uuid:job_id>/status/', PaymentStatusView.as_view(), name='payment-status'),
    path('webhook/intasend/', IntaSendWebhookView.as_view(), name='intasend-webhook'),
]
