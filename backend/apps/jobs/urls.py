from django.urls import path
from apps.jobs.views import (
    JobListView, JobCreateView, JobDetailView,
    ApplyForJobView, JobApplicationsView, AcceptApplicationView,
    CompleteJobView, SubmitReviewView,
    WorkerApplicationsView, StartJobView, CancelJobView, DisputeJobView,
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
    path('my-applications/', WorkerApplicationsView.as_view(), name='my-applications'),
    path('<uuid:pk>/start/', StartJobView.as_view(), name='start-job'),
    path('<uuid:pk>/cancel/', CancelJobView.as_view(), name='cancel-job'),
    path('<uuid:pk>/dispute/', DisputeJobView.as_view(), name='dispute-job'),
]
