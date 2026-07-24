import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/rating_model.dart';
import '../../services/chat_service.dart';
import '../../services/rating_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

final applicationsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        return Stream.value(const []);
      }

      return FirebaseFirestore.instance
          .collection('applications')
          .where('workerId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((document) => {'id': document.id, ...document.data()})
                .toList(),
          );
    });

class MyApplicationsScreen extends ConsumerStatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  ConsumerState<MyApplicationsScreen> createState() =>
      _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends ConsumerState<MyApplicationsScreen> {
  String _selectedGroup = 'pending';

  static const _groups = <String, List<String>>{
    'pending': ['pending', 'payment_pending'],
    'active': ['accepted', 'in_progress'],
    'completed': ['completed'],
    'declined': ['declined', 'cancelled'],
  };

  Future<void> _refreshApplications() async {
    ref.invalidate(applicationsProvider);

    try {
      await ref.read(applicationsProvider.future);
    } catch (_) {
      // The error state communicates refresh failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationsProvider);

    return Scaffold(
      bottomNavigationBar: Widgets.bottomNav(
        currentIndex: 1,
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
      ),
      body: applicationsAsync.when(
        loading: () => const _ApplicationsLoadingView(),
        error: (_, _) => _ApplicationsErrorView(onRetry: _refreshApplications),
        data: _buildApplicationsView,
      ),
    );
  }

  Widget _buildApplicationsView(List<Map<String, dynamic>> applications) {
    int count(String group) {
      return applications.where((application) {
        return _groups[group]!.contains(application['status']);
      }).length;
    }

    final visibleApplications = applications.where((application) {
      return _groups[_selectedGroup]!.contains(application['status']);
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshApplications,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            toolbarHeight: 0,
            expandedHeight: 258,
            backgroundColor: AppTheme.primaryGreenDark,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ApplicationsHero(
                totalCount: applications.length,
                pendingCount: count('pending'),
                activeCount: count('active'),
                completedCount: count('completed'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Widgets.sectionHeader(
                context: context,
                title: 'Application activity',
                subtitle:
                    'Track each opportunity from submission to completion.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                children: [
                  _StatusFilter(
                    label: 'Pending',
                    icon: Icons.schedule_rounded,
                    count: count('pending'),
                    selected: _selectedGroup == 'pending',
                    onTap: () {
                      setState(() => _selectedGroup = 'pending');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusFilter(
                    label: 'Active',
                    icon: Icons.play_circle_outline_rounded,
                    count: count('active'),
                    selected: _selectedGroup == 'active',
                    onTap: () {
                      setState(() => _selectedGroup = 'active');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusFilter(
                    label: 'Completed',
                    icon: Icons.task_alt_rounded,
                    count: count('completed'),
                    selected: _selectedGroup == 'completed',
                    onTap: () {
                      setState(() => _selectedGroup = 'completed');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusFilter(
                    label: 'Unsuccessful',
                    icon: Icons.cancel_outlined,
                    count: count('declined'),
                    selected: _selectedGroup == 'declined',
                    onTap: () {
                      setState(() => _selectedGroup = 'declined');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          if (visibleApplications.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _EmptyApplicationsState(
                  group: _selectedGroup,
                  onDiscover: () => context.go('/jobseeker/home'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: AppSpacing.md);
                  }

                  final application = visibleApplications[index ~/ 2];

                  return _ApplicationCard(
                    application: application,
                    onOpen: () {
                      final jobId = application['jobId'] as String?;

                      if (jobId != null) {
                        context.push('/jobseeker/job/$jobId');
                      }
                    },
                    onChat: () => _openChat(application),
                    onCheckIn: () => _openCheckIn(application),
                    onReview: () => _showReviewDialog(application),
                  );
                }, childCount: visibleApplications.length * 2 - 1),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Future<void> _openChat(Map<String, dynamic> application) async {
    final jobId = application['jobId'] as String?;
    final employerId = application['employerId'] as String?;
    final workerId = FirebaseAuth.instance.currentUser?.uid;

    if (jobId == null || employerId == null || workerId == null) {
      return;
    }

    try {
      final chatId = await ChatService.getOrCreateChat(
        jobId: jobId,
        employerId: employerId,
        workerId: workerId,
      );

      if (!mounted) return;

      context.push(
        '/chat/$chatId',
        extra: {
          'otherUserId': employerId,
          'otherUserName': application['employerName'] ?? 'Employer',
        },
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The conversation could not be opened. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _openCheckIn(Map<String, dynamic> application) async {
    final jobId = application['jobId'] as String?;

    if (jobId == null) return;

    try {
      final document = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();

      final data = document.data();
      final location = data?['location'] as GeoPoint?;

      if (data == null || location == null) {
        throw StateError('The job location could not be found.');
      }

      if (!mounted) return;

      context.push(
        '/jobseeker/checkin',
        extra: {
          'jobId': jobId,
          'jobTitle': data['title'] ?? application['jobTitle'] ?? 'Job',
          'jobLat': location.latitude,
          'jobLng': location.longitude,
        },
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in could not be opened. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> application) async {
    final jobId = application['jobId'] as String?;
    final employerId = application['employerId'] as String?;

    if (jobId == null || employerId == null) return;

    final hasAlreadyRated = await RatingService.hasRatedJob(jobId);

    if (!mounted) return;

    if (hasAlreadyRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this job.')),
      );
      return;
    }

    int stars = 5;
    bool submitting = false;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            final theme = Theme.of(dialogContext);
            final scheme = theme.colorScheme;

            return AlertDialog(
              icon: const Icon(Icons.reviews_outlined),
              title: const Text('Rate the employer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How was your experience?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        tooltip: '${index + 1} stars',
                        onPressed: () {
                          setDialogState(() => stars = index + 1);
                        },
                        icon: Icon(
                          index < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: scheme.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'Share your experience (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() => submitting = true);

                          try {
                            await RatingService.submitRating(
                              jobId: jobId,
                              revieweeId: employerId,
                              stars: stars,
                              comment: commentController.text,
                              type: RatingType.workerToEmployer,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Thank you for submitting your review.',
                                ),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          } catch (_) {
                            if (dialogContext.mounted) {
                              setDialogState(() => submitting = false);
                            }

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your review could not be saved. Please try again.',
                                ),
                              ),
                            );
                          }
                        },
                  child: submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit review'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
  }
}

class _ApplicationsHero extends StatelessWidget {
  const _ApplicationsHero({
    required this.totalCount,
    required this.pendingCount,
    required this.activeCount,
    required this.completedCount,
  });

  final int totalCount;
  final int pendingCount;
  final int activeCount;
  final int completedCount;

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
            right: -54,
            top: 20,
            child: Container(
              width: 185,
              height: 185,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 28, color: Colors.white24),
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
                  const Text(
                    'YOUR WORK PIPELINE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Applications',
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
                    totalCount == 0
                        ? 'Your next opportunity can start here.'
                        : '$totalCount application'
                              '${totalCount == 1 ? '' : 's'} tracked in one place.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _ApplicationMetric(
                          value: '$pendingCount',
                          label: 'Pending',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _ApplicationMetric(
                          value: '$activeCount',
                          label: 'Active',
                          highlight: true,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _ApplicationMetric(
                          value: '$completedCount',
                          label: 'Completed',
                        ),
                      ),
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

class _ApplicationMetric extends StatelessWidget {
  const _ApplicationMetric({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppTheme.accentGold : Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: Colors.white24);
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 17),
      label: Text('$label  $count'),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onOpen,
    required this.onChat,
    required this.onCheckIn,
    required this.onReview,
  });

  final Map<String, dynamic> application;
  final VoidCallback onOpen;
  final VoidCallback onChat;
  final VoidCallback onCheckIn;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final status = application['status'] as String? ?? 'pending';
    final appliedAt = application['appliedAt'] as Timestamp?;
    final salary = (application['jobSalary'] as num?)?.toDouble() ?? 0;
    final jobTitle = application['jobTitle'] as String? ?? 'Job';
    final neighborhood =
        application['jobNeighborhood'] as String? ?? 'Location not provided';

    final active = status == 'accepted' || status == 'in_progress';
    final statusVisual = _statusVisual(status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.work_outline_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                neighborhood,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _ApplicationStatusBadge(status: statusVisual),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ApplicationDetail(
                      icon: Icons.payments_outlined,
                      label: 'JOB VALUE',
                      value: salary > 0
                          ? 'KES ${salary.toStringAsFixed(0)}'
                          : 'Not provided',
                    ),
                  ),
                  if (appliedAt != null) ...[
                    Container(
                      width: 1,
                      height: 42,
                      color: scheme.outlineVariant,
                    ),
                    Expanded(
                      child: _ApplicationDetail(
                        icon: Icons.calendar_today_outlined,
                        label: 'APPLIED',
                        value: DateFormat(
                          'd MMM yyyy',
                        ).format(appliedAt.toDate()),
                      ),
                    ),
                  ],
                ],
              ),
              if (active || status == 'completed') ...[
                const SizedBox(height: AppSpacing.md),
                Divider(color: scheme.outlineVariant),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onChat,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: status == 'completed'
                          ? FilledButton.icon(
                              onPressed: onReview,
                              icon: const Icon(Icons.star_outline_rounded),
                              label: const Text('Review'),
                            )
                          : FilledButton.icon(
                              onPressed: onCheckIn,
                              icon: Icon(
                                status == 'in_progress'
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline_rounded,
                              ),
                              label: Text(
                                status == 'in_progress'
                                    ? 'Finish job'
                                    : 'Start job',
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationDetail extends StatelessWidget {
  const _ApplicationDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 19, color: scheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApplicationStatusBadge extends StatelessWidget {
  const _ApplicationStatusBadge({required this.status});

  final _StatusVisual status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyApplicationsState extends StatelessWidget {
  const _EmptyApplicationsState({
    required this.group,
    required this.onDiscover,
  });

  final String group;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final details = switch (group) {
      'active' => (
        Icons.hourglass_empty_rounded,
        'No active work',
        'Accepted jobs and work currently in progress will appear here.',
      ),
      'completed' => (
        Icons.task_alt_rounded,
        'No completed jobs yet',
        'Completed work and employer-review actions will appear here.',
      ),
      'declined' => (
        Icons.shield_outlined,
        'Nothing unsuccessful',
        'Declined and cancelled applications will appear here.',
      ),
      _ => (
        Icons.send_outlined,
        'No pending applications',
        'Discover nearby opportunities and submit your first application.',
      ),
    };

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
              child: Icon(details.$1, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              details.$2,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              details.$3,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (group == 'pending') ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onDiscover,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Discover jobs'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationsLoadingView extends StatelessWidget {
  const _ApplicationsLoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          expandedHeight: 258,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _ApplicationsHero(
              totalCount: 0,
              pendingCount: 0,
              activeCount: 0,
              completedCount: 0,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == 2 ? 0 : AppSpacing.md,
                ),
                child: Widgets.shimmerLoader(height: 190),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicationsErrorView extends StatelessWidget {
  const _ApplicationsErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

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
                    radius: 34,
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    child: const Icon(Icons.cloud_off_rounded, size: 30),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Applications are unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Check your connection and try loading your application history again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
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

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_StatusVisual _statusVisual(String status) {
  switch (status) {
    case 'payment_pending':
      return const _StatusVisual(
        label: 'Payment',
        color: AppTheme.info,
        icon: Icons.payments_outlined,
      );
    case 'accepted':
      return const _StatusVisual(
        label: 'Accepted',
        color: AppTheme.success,
        icon: Icons.check_circle_outline_rounded,
      );
    case 'in_progress':
      return const _StatusVisual(
        label: 'Active',
        color: AppTheme.teal,
        icon: Icons.play_circle_outline_rounded,
      );
    case 'completed':
      return const _StatusVisual(
        label: 'Completed',
        color: AppTheme.inkMuted,
        icon: Icons.task_alt_rounded,
      );
    case 'declined':
      return const _StatusVisual(
        label: 'Declined',
        color: AppTheme.error,
        icon: Icons.cancel_outlined,
      );
    case 'cancelled':
      return const _StatusVisual(
        label: 'Cancelled',
        color: AppTheme.error,
        icon: Icons.block_rounded,
      );
    default:
      return const _StatusVisual(
        label: 'Pending',
        color: AppTheme.warning,
        icon: Icons.schedule_rounded,
      );
  }
}
