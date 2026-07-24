import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _composerFocusNode = FocusNode();

  bool _isSending = false;
  bool _hasDraft = false;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _markConversationAsRead();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.chatId != widget.chatId) {
      _markConversationAsRead();
    }
  }

  void _markConversationAsRead() {
    final userId = _currentUserId;

    if (userId == null) return;

    ChatService.markAsRead(widget.chatId, userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final userId = _currentUserId;

    if (text.isEmpty || userId == null || _isSending) {
      return;
    }

    setState(() => _isSending = true);

    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        senderId: userId,
        text: text,
      );

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _hasDraft = false;
      });

      _composerFocusNode.requestFocus();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your message could not be sent. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: _ConversationHeader(
          name: widget.otherUserName,
          photoUrl: widget.otherUserPhoto,
        ),
        actions: [
          IconButton(
            tooltip: 'Conversation information',
            onPressed: () {
              _showConversationInformation(context);
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: userId == null
                  ? const _SignedOutConversationState()
                  : StreamBuilder<List<MessageModel>>(
                      stream: ChatService.getMessages(widget.chatId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const _ConversationLoadingState();
                        }

                        if (snapshot.hasError) {
                          return const _ConversationErrorState();
                        }

                        final messages = snapshot.data ?? const [];

                        if (messages.isEmpty) {
                          return _EmptyConversationState(
                            name: widget.otherUserName,
                          );
                        }

                        _markConversationAsRead();

                        return ListView.builder(
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMine = message.senderId == userId;

                            final previousMessage = index + 1 < messages.length
                                ? messages[index + 1]
                                : null;

                            final showAvatar =
                                !isMine &&
                                (previousMessage == null ||
                                    previousMessage.senderId !=
                                        message.senderId);

                            return _MessageBubble(
                              message: message,
                              isMine: isMine,
                              showAvatar: showAvatar,
                              otherUserName: widget.otherUserName,
                              otherUserPhoto: widget.otherUserPhoto,
                            );
                          },
                        );
                      },
                    ),
            ),
            _MessageComposer(
              controller: _messageController,
              focusNode: _composerFocusNode,
              enabled: userId != null,
              hasDraft: _hasDraft,
              isSending: _isSending,
              onChanged: (value) {
                final hasDraft = value.trim().isNotEmpty;

                if (hasDraft != _hasDraft) {
                  setState(() {
                    _hasDraft = hasDraft;
                  });
                }
              },
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showConversationInformation(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProfileAvatar(
                  name: widget.otherUserName,
                  photoUrl: widget.otherUserPhoto,
                  radius: 38,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.otherUserName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Job conversation',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Keep job details and payment arrangements inside Kazi for a clear record of the agreement.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        _ProfileAvatar(name: name, photoUrl: photoUrl, radius: 21),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Job conversation',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.photoUrl,
    required this.radius,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = photoUrl?.trim() ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
      child: photo.isEmpty
          ? Text(
              _initials(name),
              style: TextStyle(
                fontSize: radius * 0.55,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showAvatar,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  final MessageModel message;
  final bool isMine;
  final bool showAvatar;
  final String otherUserName;
  final String? otherUserPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;

    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xxs,
        bottom: showAvatar ? AppSpacing.sm : AppSpacing.xxs,
      ),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showAvatar)
              _ProfileAvatar(
                name: otherUserName,
                photoUrl: otherUserPhoto,
                radius: 15,
              )
            else
              const SizedBox(width: 30),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: AppMotion.standard,
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isMine ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.md),
                  topRight: const Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(
                    !isMine && showAvatar ? AppRadius.xs : AppRadius.md,
                  ),
                  bottomRight: Radius.circular(
                    isMine ? AppRadius.xs : AppRadius.md,
                  ),
                ),
                border: isMine
                    ? null
                    : Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.035),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMine ? scheme.onPrimary : scheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMine
                              ? scheme.onPrimary.withValues(alpha: 0.72)
                              : scheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: scheme.onPrimary.withValues(alpha: 0.72),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasDraft,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasDraft;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 10,
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          MediaQuery.paddingOf(context).bottom + AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled && !isSending,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: enabled
                      ? 'Write a message'
                      : 'Sign in to send messages',
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                ),
                onChanged: onChanged,
                onSubmitted: (_) {
                  if (hasDraft && !isSending) {
                    onSend();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedContainer(
              duration: AppMotion.standard,
              width: 50,
              height: 50,
              child: IconButton.filled(
                tooltip: 'Send message',
                onPressed: enabled && hasDraft && !isSending ? onSend : null,
                icon: isSending
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationLoadingState extends StatelessWidget {
  const _ConversationLoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      reverse: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (var index = 0; index < 6; index++)
          Align(
            alignment: index.isEven
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: index.isEven ? 190 : 235,
              height: index == 2 ? 82 : 58,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _ProfileAvatar(name: name, photoUrl: null, radius: 42),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start the conversation',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Message $name about the job, schedule, location, or anything needed to complete the work.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: scheme.onPrimaryContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Keep communication clear and professional.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationErrorState extends StatelessWidget {
  const _ConversationErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              child: const Icon(Icons.cloud_off_rounded, size: 31),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Conversation unavailable',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check your connection and try opening this conversation again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedOutConversationState extends StatelessWidget {
  const _SignedOutConversationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.lock_outline_rounded, size: 31),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sign in required',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to read and send messages in this conversation.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'U';

  return parts.map((part) => part[0].toUpperCase()).join();
}
