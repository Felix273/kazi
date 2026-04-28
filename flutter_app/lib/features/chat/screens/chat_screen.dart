import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import '../../../core/theme.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/bloc/auth_bloc.dart';

const String wsBaseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://10.0.2.2:8000/ws',
);

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  WebSocketChannel? _channel;
  final List<_ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _otherIsTyping = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = await StorageService().getAccessToken();
    final uri = Uri.parse('$wsBaseUrl/chat/${widget.roomId}/?token=$token');

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticatedState) {
      _myUserId = authState.user.id;
    }

    try {
      _channel = WebSocketChannel.connect(uri);
      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data as String);
          final type = decoded['type'] as String;

          if (type == 'message') {
            setState(() {
              _messages.add(_ChatMessage(
                id: decoded['message_id'],
                content: decoded['content'],
                senderId: decoded['sender_id'],
                senderName: decoded['sender_name'],
                senderPhoto: decoded['sender_photo'],
                createdAt: DateTime.parse(decoded['created_at']),
                isMe: decoded['sender_id'] == _myUserId,
              ));
              _otherIsTyping = false;
            });
            _scrollToBottom();
          } else if (type == 'typing') {
            setState(() => _otherIsTyping = decoded['is_typing'] as bool);
          }
        },
        onDone: () => setState(() => _isConnected = false),
        onError: (_) => setState(() => _isConnected = false),
      );
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || !_isConnected) return;

    _channel!.sink.add(jsonEncode({'type': 'message', 'content': text}));
    _messageCtrl.clear();
    _sendTyping(false);
  }

  void _sendTyping(bool isTyping) {
    if (_isConnected) {
      _channel!.sink.add(jsonEncode({'type': 'typing', 'is_typing': isTyping}));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Job Chat'),
            if (!_isConnected)
              const Text('Reconnecting...', style: TextStyle(
                fontSize: 11, color: KaziTheme.warning,
              )),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? KaziTheme.success : KaziTheme.error,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text('Send a message to get started', style: KaziText.body),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(KaziSpacing.md),
                    itemCount: _messages.length + (_otherIsTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_otherIsTyping && index == _messages.length) {
                        return _TypingIndicator();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              KaziSpacing.md, KaziSpacing.sm,
              KaziSpacing.md,
              MediaQuery.of(context).viewInsets.bottom + KaziSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: KaziTheme.surface,
              border: Border(top: BorderSide(color: KaziTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KaziSpacing.md, vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: KaziTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: KaziTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: KaziTheme.primary),
                      ),
                      fillColor: KaziTheme.surfaceWarm,
                      filled: true,
                    ),
                    onChanged: (v) => _sendTyping(v.isNotEmpty),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: KaziSpacing.sm),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: KaziTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final DateTime createdAt;
  final bool isMe;

  _ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.createdAt,
    required this.isMe,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KaziSpacing.sm),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: KaziTheme.surfaceWarm,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Sora', fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? KaziTheme.primary : KaziTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
              ),
              border: message.isMe ? null : Border.all(color: KaziTheme.border),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 14,
                color: message.isMe ? Colors.white : KaziTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: KaziTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: KaziTheme.border),
          ),
          child: Row(
            children: [
              _dot(0),
              const SizedBox(width: 4),
              _dot(150),
              const SizedBox(width: 4),
              _dot(300),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            color: KaziTheme.textHint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
