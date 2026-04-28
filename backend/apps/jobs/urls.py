from django.urls import path
from apps.jobs.views import (
    JobListView, JobCreateView, JobDetailView,
    ApplyForJobView, JobApplicationsView, AcceptApplicationView,
    CompleteJobView, SubmitReviewView, InitiatePaymentView,
)

urlpatterns = [
    path('', JobListView.as_view(), name='job-list'),
    path('create/', JobCreateView.as_view(), name='job-create'),
    path('<uuid:pk>/', JobDetailView.as_view(), name='job-detail'),
    path('<uuid:pk>/apply/', ApplyForJobView.as_view(), name='job-apply'),
    path('<uuid:pk>/applications/', JobApplicationsView.as_view(), name='job-applications'),
    path('<uuid:pk>/applications/<uuid:application_id>/accept/', AcceptApplicationView.as_view(), name='accept-application'),
    path('<uuid:pk>/complete/', CompleteJobView.as_view(), name='complete-job'),
    path('<uuid:pk>/review/', SubmitReviewView.as_view(), name='submit-review'),
    path('payments/initiate/', InitiatePaymentView.as_view(), name='initiate-payment'),
]
