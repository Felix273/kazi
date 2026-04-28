from django.urls import path
from apps.notifications.views import NotificationListView, MarkNotificationReadView

urlpatterns = [
    path('', NotificationListView.as_view(), name='notifications'),
    path('<uuid:pk>/read/', MarkNotificationReadView.as_view(), name='mark-read'),
]
