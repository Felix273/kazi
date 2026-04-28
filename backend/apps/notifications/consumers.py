import json
from channels.generic.websocket import AsyncWebsocketConsumer


class NotificationConsumer(AsyncWebsocketConsumer):
    """
    Each authenticated user gets their own notification channel.
    The backend pushes job alerts, payment updates, and chat pings here.
    Flutter subscribes on app launch.
    """

    async def connect(self):
        self.user = self.scope['user']
        if not self.user.is_authenticated:
            await self.close()
            return

        self.group_name = f'notifications_{self.user.id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    # Called by backend services via channel_layer.group_send
    async def notify(self, event):
        await self.send(text_data=json.dumps({
            'type': event['notification_type'],
            'title': event.get('title', ''),
            'body': event.get('body', ''),
            'data': event.get('data', {}),
        }))
