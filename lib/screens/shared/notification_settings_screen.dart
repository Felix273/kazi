import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _newJobNotifications = true;
  bool _applicationNotifications = true;
  bool _chatNotifications = true;
  bool _paymentNotifications = true;
  bool _promotionalNotifications = false;

  bool _loading = true;
  bool _saving = false;
  bool _sendingTest = false;
  String? _loadError;

  int get _enabledCount => [
    _newJobNotifications,
    _applicationNotifications,
    _chatNotifications,
    _paymentNotifications,
    _promotionalNotifications,
  ].where((enabled) => enabled).length;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'Sign in to manage notification preferences.';
      });
      return;
    }

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final settings = Map<String, dynamic>.from(
        document.data()?['notificationSettings'] as Map? ?? const {},
      );

      if (!mounted) return;

      setState(() {
        _newJobNotifications = settings['newJobs'] as bool? ?? true;
        _applicationNotifications = settings['applications'] as bool? ?? true;
        _chatNotifications = settings['chat'] as bool? ?? true;
        _paymentNotifications = settings['payments'] as bool? ?? true;
        _promotionalNotifications = settings['promotions'] as bool? ?? false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = 'Your notification preferences could not be loaded.';
      });
    }
  }

  Future<void> _saveSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'notificationSettings': {
        'newJobs': _newJobNotifications,
        'applications': _applicationNotifications,
        'chat': _chatNotifications,
        'payments': _paymentNotifications,
        'promotions': _promotionalNotifications,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateSetting({
    required VoidCallback update,
    required VoidCallback rollback,
  }) async {
    if (_saving) return;

    setState(() {
      update();
      _saving = true;
    });

    try {
      await _saveSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Notification preference saved.'),
            duration: Duration(seconds: 2),
          ),
        );
    } catch (_) {
      if (!mounted) return;

      setState(rollback);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The preference could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _sendTestNotification() async {
    if (_sendingTest) return;

    setState(() => _sendingTest = true);

    try {
      await NotificationService.sendLocalNotification(
        title: 'Kazi',
        body: 'Notifications are working correctly on this device.',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The test notification could not be sent. Check your device permissions.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingTest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 290,
              backgroundColor: AppTheme.primaryGreenDark,
              foregroundColor: Colors.white,
              title: const Text('Notifications'),
              actions: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.lg),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _NotificationHero(enabledCount: _enabledCount),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationLoadingState(),
              )
            else if (_loadError != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationErrorState(
                  message: _loadError!,
                  onRetry: _loadSettings,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: _NotificationIntroduction(enabledCount: _enabledCount),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: _NotificationSectionCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Job activity',
                    description:
                        'Updates about opportunities and applications.',
                    children: [
                      _NotificationPreferenceTile(
                        icon: Icons.location_searching_rounded,
                        title: 'New job matches',
                        subtitle:
                            'Relevant opportunities posted near your preferred search area.',
                        value: _newJobNotifications,
                        enabled: !_saving,
                        onChanged: (value) {
                          final previous = _newJobNotifications;

                          _updateSetting(
                            update: () {
                              _newJobNotifications = value;
                            },
                            rollback: () {
                              _newJobNotifications = previous;
                            },
                          );
                        },
                      ),
                      _NotificationPreferenceTile(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Application updates',
                        subtitle:
                            'Status changes, hiring decisions, and job progress.',
                        value: _applicationNotifications,
                        enabled: !_saving,
                        onChanged: (value) {
                          final previous = _applicationNotifications;

                          _updateSetting(
                            update: () {
                              _applicationNotifications = value;
                            },
                            rollback: () {
                              _applicationNotifications = previous;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _NotificationSectionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Messages',
                    description: 'Stay informed when someone contacts you.',
                    children: [
                      _NotificationPreferenceTile(
                        icon: Icons.mark_chat_unread_outlined,
                        title: 'New messages',
                        subtitle: 'Alerts for new employer or worker messages.',
                        value: _chatNotifications,
                        enabled: !_saving,
                        onChanged: (value) {
                          final previous = _chatNotifications;

                          _updateSetting(
                            update: () {
                              _chatNotifications = value;
                            },
                            rollback: () {
                              _chatNotifications = previous;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _NotificationSectionCard(
                    icon: Icons.payments_outlined,
                    title: 'Payments',
                    description: 'Important updates about your money.',
                    children: [
                      _NotificationPreferenceTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payment updates',
                        subtitle:
                            'Wallet deposits, payments, and withdrawal progress.',
                        value: _paymentNotifications,
                        enabled: !_saving,
                        onChanged: (value) {
                          final previous = _paymentNotifications;

                          _updateSetting(
                            update: () {
                              _paymentNotifications = value;
                            },
                            rollback: () {
                              _paymentNotifications = previous;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _NotificationSectionCard(
                    icon: Icons.campaign_outlined,
                    title: 'Kazi updates',
                    description: 'Optional product news and offers.',
                    children: [
                      _NotificationPreferenceTile(
                        icon: Icons.local_offer_outlined,
                        title: 'News and offers',
                        subtitle:
                            'Occasional feature announcements and relevant promotions.',
                        value: _promotionalNotifications,
                        enabled: !_saving,
                        onChanged: (value) {
                          final previous = _promotionalNotifications;

                          _updateSetting(
                            update: () {
                              _promotionalNotifications = value;
                            },
                            rollback: () {
                              _promotionalNotifications = previous;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _TestNotificationCard(
                    sending: _sendingTest,
                    onSend: _sendTestNotification,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: _DevicePermissionNotice(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({required this.enabledCount});

  final int enabledCount;

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
            right: -55,
            top: 25,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 28, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: -56,
            child: Container(
              width: 145,
              height: 145,
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
                88,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.accentGold,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Stay informed.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Choose the updates that matter and keep unnecessary alerts quiet.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$enabledCount of 5 categories enabled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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

class _NotificationIntroduction extends StatelessWidget {
  const _NotificationIntroduction({required this.enabledCount});

  final int enabledCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification preferences',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Changes are saved automatically to your Kazi account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        CircleAvatar(
          radius: 24,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(
            '$enabledCount',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _NotificationSectionCard extends StatelessWidget {
  const _NotificationSectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          ...List.generate(
            children.length,
            (index) => Column(
              children: [
                children[index],
                if (index < children.length - 1)
                  Divider(height: 1, indent: 72, color: scheme.outlineVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  const _NotificationPreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      secondary: CircleAvatar(
        radius: 20,
        backgroundColor: value
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        foregroundColor: value
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant,
        child: Icon(icon, size: 19),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _TestNotificationCard extends StatelessWidget {
  const _TestNotificationCard({required this.sending, required this.onSend});

  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: const Icon(Icons.notifications_active_rounded),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test this device',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Send a sample notification to confirm delivery.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.tonalIcon(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(sending ? 'Sending…' : 'Send'),
          ),
        ],
      ),
    );
  }
}

class _DevicePermissionNotice extends StatelessWidget {
  const _DevicePermissionNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 19,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Notification delivery also depends on your device permissions, battery settings, and internet connection.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationLoadingState extends StatelessWidget {
  const _NotificationLoadingState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading notification preferences…',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  const _NotificationErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
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
                  radius: 35,
                  backgroundColor: scheme.errorContainer,
                  foregroundColor: scheme.onErrorContainer,
                  child: const Icon(Icons.cloud_off_rounded, size: 31),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Preferences unavailable',
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
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
