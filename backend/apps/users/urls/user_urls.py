from django.urls import path
from apps.users.views.user_views import (
    MyProfileView, UpdateLocationView, UpdateFCMTokenView,
    SetOnlineStatusView, NearbyWorkersView,
    PublicProfileView, SkillListView,
    KYCSubmitView, KYCWebhookView
)

urlpatterns = [
    path('me/', MyProfileView.as_view(), name='my-profile'),
    path('location/', UpdateLocationView.as_view(), name='update-location'),
    path('fcm-token/', UpdateFCMTokenView.as_view(), name='update-fcm-token'),
    path('online-status/', SetOnlineStatusView.as_view(), name='online-status'),
    path('nearby-workers/', NearbyWorkersView.as_view(), name='nearby-workers'),
    path('profile/<uuid:user_id>/', PublicProfileView.as_view(), name='public-profile'),
    path('skills/', SkillListView.as_view(), name='skills'),
    path('kyc/submit/', KYCSubmitView.as_view(), name='kyc-submit'),
    path('kyc/webhook/', KYCWebhookView.as_view(), name='kyc-webhook'),
]
