import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/job_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

final employerJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value(const <JobModel>[]);
  }

  return FirebaseFirestore.instance
      .collection('jobs')
      .where('employerId', isEqualTo: userId)
      .where(
        'status',
        whereIn: ['open', 'payment_pending', 'hired', 'completed'],
      )
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((document) {
          return JobModel.fromMap(document.data(), document.id);
        }).toList(),
      );
});

final employerProfileProvider =
    StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        return Stream.value(null);
      }

      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) => snapshot.data());
    });

class EmployerDashboardScreen extends ConsumerWidget {
  const EmployerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(employerJobsProvider);
    final profileAsync = ref.watch(employerProfileProvider);
    final profile = profileAsync.asData?.value;
    final jobs = jobsAsync.asData?.value ?? const <JobModel>[];

    final employerName = (profile?['name'] as String?)?.trim();
    final photoUrl = (profile?['photoUrl'] as String?)?.trim();

    final openJobs = jobs.where((job) => job.status == 'open').length;
    final completedJobs = jobs.where((job) => job.status == 'completed').length;
    final applicantCount = jobs.fold<int>(
      0,
      (total, job) => total + job.applicantCount,
    );

    Future<void> refreshDashboard() async {
      ref.invalidate(employerJobsProvider);
      ref.invalidate(employerProfileProvider);

      try {
        await ref.read(employerJobsProvider.future);
      } catch (_) {
        // The dashboard error state communicates refresh failures.
      }
    }

    return Scaffold(
      bottomNavigationBar: Widgets.employerBottomNav(context),
      body: RefreshIndicator(
        onRefresh: refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              toolbarHeight: 0,
              expandedHeight: 330,
              backgroundColor: AppTheme.primaryGreenDark,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _EmployerHero(
                  employerName: employerName?.isNotEmpty == true
                      ? employerName!
                      : 'Employer',
                  photoUrl: photoUrl,
                  openJobs: openJobs,
                  applicantCount: applicantCount,
                  completedJobs: completedJobs,
                  onPostJob: () => context.push('/employer/post-job'),
                  onNotifications: () {
                    context.push('/settings/notifications');
                  },
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
                  title: 'Your jobs',
                  subtitle: jobs.isEmpty
                      ? 'Post work and start receiving applications.'
                      : '${jobs.length} job'
                            '${jobs.length == 1 ? '' : 's'} in your workspace.',
                ),
              ),
            ),
            _buildJobsSliver(context: context, ref: ref, jobsAsync: jobsAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 108)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsSliver({
    required BuildContext context,
    required WidgetRef ref,
    required AsyncValue<List<JobModel>> jobsAsync,
  }) {
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _EmployerStateCard(
                icon: Icons.add_business_rounded,
                title: 'Post your first job',
                message:
                    'Describe the work, set your budget, and nearby '
                    'professionals can start applying.',
                actionLabel: 'Create job',
                onAction: () => context.push('/employer/post-job'),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) {
                return const SizedBox(height: AppSpacing.md);
              }

              final job = jobs[index ~/ 2];

              return _EmployerJobCard(job: job, jobId: job.id);
            }, childCount: jobs.length * 2 - 1),
          ),
        );
      },
      loading: () {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((_, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == 2 ? 0 : AppSpacing.md,
                ),
                child: Widgets.shimmerLoader(height: 210),
              );
            }, childCount: 3),
          ),
        );
      },
      error: (_, _) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _EmployerStateCard(
              icon: Icons.cloud_off_rounded,
              title: 'Your jobs are unavailable',
              message: 'Check your connection and refresh the dashboard.',
              actionLabel: 'Try again',
              onAction: () => ref.invalidate(employerJobsProvider),
            ),
          ),
        );
      },
    );
  }
}

class _EmployerHero extends StatelessWidget {
  const _EmployerHero({
    required this.employerName,
    required this.photoUrl,
    required this.openJobs,
    required this.applicantCount,
    required this.completedJobs,
    required this.onPostJob,
    required this.onNotifications,
  });

  final String employerName;
  final String? photoUrl;
  final int openJobs;
  final int applicantCount;
  final int completedJobs;
  final VoidCallback onPostJob;
  final VoidCallback onNotifications;

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
            top: 38,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 30, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            right: 96,
            bottom: -42,
            child: Container(
              width: 120,
              height: 120,
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
                  Row(
                    children: [
                      _ProfileAvatar(name: employerName, photoUrl: photoUrl),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMPLOYER WORKSPACE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              employerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Notifications',
                        onPressed: onNotifications,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Build your team.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Post local work, review applicants, and hire '
                    'with confidence.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onPostJob,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: const Color(0xFF3E2D00),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Post a new job'),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          value: '$openJobs',
                          label: 'Open jobs',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _HeroMetric(
                          value: '$applicantCount',
                          label: 'Applicants',
                          highlight: true,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _HeroMetric(
                          value: '$completedJobs',
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = name.trim().isEmpty
        ? 'E'
        : name.trim().substring(0, 1).toUpperCase();

    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accentGold,
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppTheme.primaryGreenDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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
          textAlign: TextAlign.center,
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

class _EmployerJobCard extends StatelessWidget {
  const _EmployerJobCard({required this.job, required this.jobId});

  final JobModel job;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _statusVisual(job.status);
    final applicantLabel =
        '${job.applicantCount} applicant'
        '${job.applicantCount == 1 ? '' : 's'}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/employer/job/$jobId'),
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
                      _categoryIcon(job.category),
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          job.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _InfoPill(
                    icon: Icons.location_on_outlined,
                    label: job.neighborhood,
                  ),
                  _InfoPill(
                    icon: Icons.calendar_today_outlined,
                    label: '${job.startDate.day}/${job.startDate.month}',
                  ),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: 'KES ${job.salaryKES.toStringAsFixed(0)}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: job.applicantCount > 0
                          ? scheme.secondaryContainer
                          : scheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.groups_2_outlined,
                      size: 20,
                      color: job.applicantCount > 0
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicantLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          job.applicantCount > 0
                              ? 'Review candidates for this job.'
                              : 'Waiting for the first application.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.push('/employer/job/$jobId/applicants');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    iconAlignment: IconAlignment.end,
                    label: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployerStateCard extends StatelessWidget {
  const _EmployerStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

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
              radius: 32,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
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
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
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
    case 'open':
      return const _StatusVisual(
        label: 'Open',
        color: AppTheme.success,
        icon: Icons.radio_button_checked_rounded,
      );
    case 'payment_pending':
      return const _StatusVisual(
        label: 'Payment',
        color: AppTheme.warning,
        icon: Icons.schedule_rounded,
      );
    case 'hired':
      return const _StatusVisual(
        label: 'Hired',
        color: AppTheme.info,
        icon: Icons.how_to_reg_rounded,
      );
    case 'completed':
      return const _StatusVisual(
        label: 'Completed',
        color: AppTheme.inkMuted,
        icon: Icons.check_circle_outline_rounded,
      );
    default:
      return _StatusVisual(
        label: status,
        color: AppTheme.inkMuted,
        icon: Icons.info_outline_rounded,
      );
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'plumbing':
      return Icons.plumbing_rounded;
    case 'electrical':
      return Icons.electrical_services_rounded;
    case 'delivery':
      return Icons.delivery_dining_rounded;
    case 'security':
      return Icons.security_rounded;
    case 'cooking':
      return Icons.restaurant_rounded;
    case 'childcare':
      return Icons.child_care_rounded;
    case 'painting':
      return Icons.format_paint_rounded;
    case 'carpentry':
      return Icons.carpenter_rounded;
    case 'gardening':
      return Icons.yard_rounded;
    case 'driving':
      return Icons.drive_eta_rounded;
    case 'events':
      return Icons.event_rounded;
    case 'casual labour':
      return Icons.construction_rounded;
    default:
      return Icons.work_rounded;
  }
}
