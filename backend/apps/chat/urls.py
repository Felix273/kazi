from django.urls import path
from apps.chat.views import ChatRoomView, ChatMessagesView

urlpatterns = [
    path('<uuid:job_id>/', ChatRoomView.as_view(), name='chat-room'),
    path('<uuid:room_id>/messages/', ChatMessagesView.as_view(), name='chat-messages'),
]
