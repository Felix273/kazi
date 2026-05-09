from django.urls import path
from apps.users.views.user_views import (
    MyProfileView, UpdateLocationView, UpdateFCMTokenView,
    SetOnlineStatusView, NearbyWorkersView,
    PublicProfileView, SkillListView, SubmitKYCView,
    KYCStatusView, WorkerProfileUpdateView
)

urlpatterns = [
    path('me/', MyProfileView.as_view(), name='my-profile'),
    path('location/', UpdateLocationView.as_view(), name='update-location'),
    path('fcm-token/', UpdateFCMTokenView.as_view(), name='update-fcm-token'),
    path('online-status/', SetOnlineStatusView.as_view(), name='online-status'),
    path('nearby-workers/', NearbyWorkersView.as_view(), name='nearby-workers'),
    path('profile/<uuid:user_id>/', PublicProfileView.as_view(), name='public-profile'),
    path('skills/', SkillListView.as_view(), name='skills'),
    path('kyc/submit/', SubmitKYCView.as_view(), name='submit-kyc'),
    path('kyc/status/', KYCStatusView.as_view(), name='kyc-status'),
    path('me/worker-profile/', WorkerProfileUpdateView.as_view(), name='worker-profile-update'),
]
