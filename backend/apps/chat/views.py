from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from apps.chat.models import ChatRoom, Message
from apps.chat.serializers import ChatRoomSerializer, MessageSerializer


class ChatRoomView(APIView):
    def get(self, request, job_id):
        try:
            room = ChatRoom.objects.get(
                job_id=job_id,
                **{'employer': request.user} if request.user == request.user else {'worker': request.user}
            )
        except ChatRoom.DoesNotExist:
            # Try either side
            room = ChatRoom.objects.filter(
                job_id=job_id
            ).filter(
                employer=request.user
            ).first() or ChatRoom.objects.filter(
                job_id=job_id, worker=request.user
            ).first()

        if not room:
            return Response({'detail': 'Chat room not found.'}, status=status.HTTP_404_NOT_FOUND)

        return Response(ChatRoomSerializer(room).data)


class ChatMessagesView(APIView):
    def get(self, request, room_id):
        try:
            room = ChatRoom.objects.get(id=room_id)
        except ChatRoom.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)

        if request.user not in [room.employer, room.worker]:
            return Response({'detail': 'Unauthorized.'}, status=status.HTTP_403_FORBIDDEN)

        messages = room.messages.order_by('-created_at')

        paginator = PageNumberPagination()
        paginator.page_size = 30
        page = paginator.paginate_queryset(messages, request)
        return paginator.get_paginated_response(MessageSerializer(page, many=True).data)
