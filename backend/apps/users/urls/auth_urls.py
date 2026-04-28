# apps/users/urls/auth_urls.py
from django.urls import path
from apps.users.views.auth_views import (
    RequestOTPView, VerifyOTPView,
    CompleteRegistrationView, RefreshTokenView
)

urlpatterns = [
    path('request-otp/', RequestOTPView.as_view(), name='request-otp'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('complete-registration/', CompleteRegistrationView.as_view(), name='complete-registration'),
    path('refresh/', RefreshTokenView.as_view(), name='token-refresh'),
]
