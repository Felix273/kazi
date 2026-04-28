import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from apps.chat.models import ChatRoom, Message
import logging

logger = logging.getLogger(__name__)
User = get_user_model()


class ChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time in-app chat.
    Flutter connects to: ws://server/ws/chat/{room_id}/
    """

    async def connect(self):
        self.room_id = self.scope['url_route']['kwargs']['room_id']
        self.room_group_name = f'chat_{self.room_id}'
        self.user = self.scope['user']

        if not self.user.is_authenticated:
            await self.close()
            return

        # Verify user belongs to this chat room
        if not await self.user_in_room(self.room_id, self.user):
            await self.close()
            return

        # Join the room channel group
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

        # Mark user as read
        await self.mark_messages_read(self.room_id, self.user)

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        """Handle incoming message from Flutter client"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type', 'message')

            if message_type == 'message':
                content = data.get('content', '').strip()
                if not content:
                    return

                # Save to database
                message = await self.save_message(self.room_id, self.user, content)

                # Broadcast to all users in room
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'chat_message',
                        'message_id': str(message.id),
                        'content': message.content,
                        'sender_id': str(self.user.id),
                        'sender_name': self.user.full_name,
                        'sender_photo': self.user.profile_photo.url if self.user.profile_photo else None,
                        'created_at': message.created_at.isoformat(),
                        'message_type': message.message_type,
                    }
                )

            elif message_type == 'typing':
                # Broadcast typing indicator (not saved)
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        'type': 'typing_indicator',
                        'user_id': str(self.user.id),
                        'is_typing': data.get('is_typing', False),
                    }
                )

        except json.JSONDecodeError:
            logger.warning(f"Invalid JSON received in chat room {self.room_id}")

    async def chat_message(self, event):
        """Send message to WebSocket client"""
        await self.send(text_data=json.dumps({
            'type': 'message',
            **{k: v for k, v in event.items() if k != 'type'}
        }))

    async def typing_indicator(self, event):
        """Send typing indicator to WebSocket client"""
        if event['user_id'] != str(self.user.id):
            await self.send(text_data=json.dumps({
                'type': 'typing',
                'user_id': event['user_id'],
                'is_typing': event['is_typing'],
            }))

    @database_sync_to_async
    def user_in_room(self, room_id, user):
        try:
            room = ChatRoom.objects.get(id=room_id)
            return room.employer == user or room.worker == user
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, room_id, user, content):
        room = ChatRoom.objects.get(id=room_id)
        return Message.objects.create(
            room=room,
            sender=user,
            content=content,
            message_type=Message.MessageType.TEXT,
        )

    @database_sync_to_async
    def mark_messages_read(self, room_id, user):
        Message.objects.filter(
            room_id=room_id,
            is_read=False
        ).exclude(sender=user).update(is_read=True)
