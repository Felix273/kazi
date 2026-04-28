from rest_framework import serializers
from apps.chat.models import ChatRoom, Message


class MessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()
    sender_photo = serializers.SerializerMethodField()
    sender_id = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ['id', 'content', 'message_type', 'is_read',
                  'created_at', 'sender_id', 'sender_name', 'sender_photo']

    def get_sender_id(self, obj): return str(obj.sender.id) if obj.sender else None
    def get_sender_name(self, obj): return obj.sender.full_name if obj.sender else 'System'
    def get_sender_photo(self, obj):
        if obj.sender and obj.sender.profile_photo:
            return obj.sender.profile_photo.url
        return None


class ChatRoomSerializer(serializers.ModelSerializer):
    job_title = serializers.SerializerMethodField()
    other_user_name = serializers.SerializerMethodField()
    other_user_photo = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = [
            'id', 'job_id', 'job_title', 'is_active',
            'other_user_name', 'other_user_photo',
            'unread_count', 'last_message', 'created_at',
        ]

    def get_job_title(self, obj): return obj.job.title

    def get_other_user_name(self, obj):
        request = self.context.get('request')
        if request:
            other = obj.worker if request.user == obj.employer else obj.employer
            return other.full_name
        return ''

    def get_other_user_photo(self, obj):
        request = self.context.get('request')
        if request:
            other = obj.worker if request.user == obj.employer else obj.employer
            return other.profile_photo.url if other.profile_photo else None
        return None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0

    def get_last_message(self, obj):
        last = obj.messages.order_by('-created_at').first()
        if last:
            return {'content': last.content[:80], 'created_at': last.created_at}
        return None
