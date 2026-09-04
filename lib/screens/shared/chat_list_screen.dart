import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';

import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key, this.roleHint});

  final String? roleHint;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      final isEmployer = roleHint == AppConstants.roleEmployer;

      return Scaffold(
        bottomNavigationBar: _MessagesNavigation(isEmployer: isEmployer),
        body: const _SignedOutMessagesState(),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.getUserProfile(userId),
      builder: (context, profileSnapshot) {
        final role =
            profileSnapshot.data?.role ??
            roleHint ??
            AppConstants.roleJobseeker;
        final isEmployer = role == 'employer';

        return Scaffold(
          bottomNavigationBar: _MessagesNavigation(isEmployer: isEmployer),
          body: StreamBuilder<List<ChatModel>>(
            stream: ChatService.getChatList(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.hasError) {
                return _MessagesStateView(
                  isEmployer: isEmployer,
                  icon: Icons.cloud_off_rounded,
                  title: 'Messages are unavailable',
                  message:
                      'Check your connection and try loading your conversations again.',
                );
              }

              if (!chatSnapshot.hasData) {
                return _MessagesLoadingView(isEmployer: isEmployer);
              }

              final chats = chatSnapshot.data!;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    pinned: true,
                    toolbarHeight: 0,
                    expandedHeight: 248,
                    backgroundColor: AppTheme.primaryGreenDark,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: _MessagesHero(
                        isEmployer: isEmployer,
                        conversationCount: chats.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Widgets.sectionHeader(
                        context: context,
                        title: 'Your conversations',
                        subtitle: isEmployer
                            ? 'Coordinate jobs and respond to your workers.'
                            : 'Stay connected with employers throughout each job.',
                      ),
                    ),
                  ),
                  if (chats.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _EmptyMessagesState(isEmployer: isEmployer),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isOdd) {
                            return const SizedBox(height: AppSpacing.sm);
                          }

                          return _ChatTile(
                            chat: chats[index ~/ 2],
                            currentUserId: userId,
                          );
                        }, childCount: chats.length * 2 - 1),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MessagesHero extends StatelessWidget {
  const _MessagesHero({
    required this.isEmployer,
    required this.conversationCount,
  });

  final bool isEmployer;
  final int conversationCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
            AppTheme.teal,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: 18,
            child: Container(
              width: 182,
              height: 182,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 28, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -60,
            child: Container(
              width: 132,
              height: 132,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEmployer ? 'EMPLOYER INBOX' : 'WORKER INBOX',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isEmployer
                        ? 'Keep every job moving with clear communication.'
                        : 'Coordinate work, arrival, and payment with confidence.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.forum_outlined,
                          size: 18,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$conversationCount conversation'
                          '${conversationCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat, required this.currentUserId});

  final ChatModel chat;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.employerId == currentUserId
        ? chat.workerId
        : chat.employerId;

    return FutureBuilder<_ChatPreviewData>(
      future: _loadPreview(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Widgets.shimmerLoader(height: 92);
        }

        final preview = snapshot.data!;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              context.push(
                '/chat/${chat.id}',
                extra: {
                  'otherUserId': otherUserId,
                  'otherUserName': preview.name,
                  'otherUserPhoto': preview.photo,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        backgroundImage: preview.photo.isEmpty
                            ? null
                            : NetworkImage(preview.photo),
                        child: preview.photo.isEmpty
                            ? Text(
                                _initials(preview.name),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      if (preview.unreadCount > 0)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 21,
                              minHeight: 21,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              preview.unreadCount > 99
                                  ? '99+'
                                  : '${preview.unreadCount}',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preview.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: preview.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          preview.message?.text.isNotEmpty == true
                              ? preview.message!.text
                              : 'Start a conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: preview.unreadCount > 0
                                ? scheme.onSurface
                                : scheme.onSurfaceVariant,
                            fontWeight: preview.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_ChatPreviewData> _loadPreview(String otherUserId) async {
    final results = await Future.wait<Object?>([
      FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      ChatService.getLastMessage(chat.id),
      ChatService.getUnreadCount(chat.id, currentUserId),
    ]);

    final userDocument = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final userData = userDocument.data() ?? const <String, dynamic>{};

    return _ChatPreviewData(
      name: userData['name'] as String? ?? 'Kazi user',
      photo: userData['photoUrl'] as String? ?? '',
      message: results[1] as MessageModel?,
      unreadCount: results[2] as int? ?? 0,
    );
  }
}

class _ChatPreviewData {
  const _ChatPreviewData({
    required this.name,
    required this.photo,
    required this.message,
    required this.unreadCount,
  });

  final String name;
  final String photo;
  final MessageModel? message;
  final int unreadCount;
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState({required this.isEmployer});

  final bool isEmployer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.forum_outlined, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No conversations yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isEmployer
                  ? 'A conversation will appear after you begin engaging with an applicant.'
                  : 'A conversation will appear after an employer accepts your application.',
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

class _MessagesLoadingView extends StatelessWidget {
  const _MessagesLoadingView({required this.isEmployer});

  final bool isEmployer;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          expandedHeight: 248,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _MessagesHero(
              isEmployer: isEmployer,
              conversationCount: 0,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == 3 ? 0 : AppSpacing.sm,
                ),
                child: Widgets.shimmerLoader(height: 92),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagesStateView extends StatelessWidget {
  const _MessagesStateView({
    required this.isEmployer,
    required this.icon,
    required this.title,
    required this.message,
  });

  final bool isEmployer;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          expandedHeight: 248,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _MessagesHero(
              isEmployer: isEmployer,
              conversationCount: 0,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                      child: Icon(icon, size: 30),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagesNavigation extends StatelessWidget {
  const _MessagesNavigation({required this.isEmployer});

  final bool isEmployer;

  @override
  Widget build(BuildContext context) {
    if (!isEmployer) {
      return Widgets.bottomNav(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/jobseeker/home');
            case 1:
              context.go('/jobseeker/applications');
            case 2:
              context.go('/jobseeker/wallet');
            case 3:
              context.go('/chat');
            case 4:
              context.go('/profile');
          }
        },
      );
    }

    return Widgets.employerBottomNav(context);
  }
}

class _SignedOutMessagesState extends StatelessWidget {
  const _SignedOutMessagesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.lock_outline_rounded, size: 31),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sign in to view messages',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your job conversations are private and available only after signing in.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.go('/role'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Continue to sign in'),
                  ),
                ],
              ),
            ),
          ),
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

  if (parts.isEmpty) return 'K';

  return parts.map((part) => part[0].toUpperCase()).join();
}
