import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/job_model.dart';
import '../../services/chat_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

class EmployerJobDetailScreen extends StatelessWidget {
  const EmployerJobDetailScreen({super.key, required this.jobId});

  final String jobId;

  Future<void> _cancelJob(BuildContext context, JobModel job) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            child: const Icon(Icons.cancel_outlined, size: 28),
          ),
          title: const Text('Cancel this job?'),
          content: Text(
            'New applications will be stopped immediately. '
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Keep job'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cancel job'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await JobService.updateJobStatus(job.id, 'cancelled');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The job has been cancelled.')),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The job could not be cancelled. Please try again.'),
        ),
      );
    }
  }

  Future<void> _openChat(BuildContext context, JobModel job) async {
    final workerId = job.hiredWorkerId;

    if (workerId == null || workerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hired worker is attached to this job yet.'),
        ),
      );
      return;
    }

    try {
      final chatId = await ChatService.getOrCreateChat(
        jobId: job.id,
        employerId: job.employerId,
        workerId: workerId,
      );

      if (!context.mounted) return;

      context.push(
        '/chat/$chatId',
        extra: {
          'otherUserId': workerId,
          'otherUserName': job.hiredWorkerName ?? 'Worker',
        },
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The conversation could not be opened. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JobModel?>(
      stream: JobService.watchJob(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: _EmployerJobLoadingView());
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: _EmployerJobStateView(
              icon: Icons.cloud_off_rounded,
              title: 'Job is unavailable',
              message: 'Check your connection and try loading this job again.',
            ),
          );
        }

        final job = snapshot.data;

        if (job == null) {
          return const Scaffold(
            body: _EmployerJobStateView(
              icon: Icons.work_off_outlined,
              title: 'Job not found',
              message:
                  'This job may have been removed or is no longer available.',
            ),
          );
        }

        return Scaffold(
          bottomNavigationBar: _EmployerJobActionBar(
            job: job,
            onViewApplicants: () {
              context.push('/employer/job/${job.id}/applicants');
            },
            onOpenChat: () => _openChat(context, job),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 360,
                backgroundColor: AppTheme.primaryGreenDark,
                foregroundColor: Colors.white,
                title: const Text('Job details'),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _EmployerJobHero(job: job),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _EmployerJobFacts(job: job),
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
                  child: _JobContentCard(
                    icon: Icons.description_outlined,
                    title: 'Job description',
                    child: Text(
                      job.description.trim().isEmpty
                          ? 'No detailed description was provided.'
                          : job.description.trim(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ),
                ),
              ),
              if (job.requirements.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _JobContentCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Worker requirements',
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < job.requirements.length;
                            index++
                          ) ...[
                            _RequirementRow(
                              requirement: job.requirements[index],
                            ),
                            if (index < job.requirements.length - 1)
                              const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (job.status == 'open')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _JobManagementCard(
                      applicantCount: job.applicantCount,
                      onViewApplicants: () {
                        context.push('/employer/job/${job.id}/applicants');
                      },
                      onBoost: () {
                        context.push('/employer/job/${job.id}/boost');
                      },
                      onCancel: () => _cancelJob(context, job),
                    ),
                  ),
                ),
              if (job.status == 'hired' || job.status == 'in_progress')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _HiredWorkerCard(
                      workerName: job.hiredWorkerName ?? 'Hired worker',
                      onOpenChat: () => _openChat(context, job),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        );
      },
    );
  }
}

class _EmployerJobHero extends StatelessWidget {
  const _EmployerJobHero({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(job.status);

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
            right: -58,
            top: 28,
            child: Container(
              width: 198,
              height: 198,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 29, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: -58,
            child: Container(
              width: 148,
              height: 148,
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.business_center_outlined,
                          color: AppTheme.accentGold,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          job.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                      _HeroStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    job.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _HeroMetadata(
                        icon: Icons.location_on_outlined,
                        label: job.neighborhood,
                      ),
                      _HeroMetadata(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat('d MMM yyyy').format(job.startDate),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JOB BUDGET',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'KES ${_formatAmount(job.salaryKES)}',
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${job.applicantCount} applicant'
                          '${job.applicantCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.status});

  final _JobStatusVisual status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 15, color: Colors.white),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmployerJobFacts extends StatelessWidget {
  const _EmployerJobFacts({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final duration = job.durationType == 'hours'
        ? '${job.duration} hour'
              '${job.duration == 1 ? '' : 's'}'
        : '${job.duration} day'
              '${job.duration == 1 ? '' : 's'}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.lg,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.groups_outlined,
                    label: 'Applicants',
                    value: '${job.applicantCount}',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.timelapse_rounded,
                    label: 'Duration',
                    value: duration,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.payments_outlined,
                    label: 'Worker payout',
                    value: 'KES ${_formatAmount(job.workerEarns)}',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.calendar_today_outlined,
                    label: 'Start date',
                    value: DateFormat('d MMM yyyy').format(job.startDate),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobFact extends StatelessWidget {
  const _JobFact({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                maxLines: 2,
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

class _JobContentCard extends StatelessWidget {
  const _JobContentCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(icon, size: 19),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.requirement});

  final String requirement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            requirement,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _JobManagementCard extends StatelessWidget {
  const _JobManagementCard({
    required this.applicantCount,
    required this.onViewApplicants,
    required this.onBoost,
    required this.onCancel,
  });

  final int applicantCount;
  final VoidCallback onViewApplicants;
  final VoidCallback onBoost;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: const Icon(Icons.tune_rounded, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Manage this job',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onViewApplicants,
              icon: const Icon(Icons.groups_outlined),
              label: Text('Review applicants ($applicantCount)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onBoost,
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Boost job visibility'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel job'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiredWorkerCard extends StatelessWidget {
  const _HiredWorkerCard({required this.workerName, required this.onOpenChat});

  final String workerName;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              _initials(workerName),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hired worker',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  workerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Message worker',
            onPressed: onOpenChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _EmployerJobActionBar extends StatelessWidget {
  const _EmployerJobActionBar({
    required this.job,
    required this.onViewApplicants,
    required this.onOpenChat,
  });

  final JobModel job;
  final VoidCallback onViewApplicants;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (job.status == 'open') {
      return Material(
        elevation: 8,
        color: scheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'APPLICANTS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${job.applicantCount}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onViewApplicants,
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('View applicants'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (job.status == 'hired' || job.status == 'in_progress') {
      return Material(
        elevation: 8,
        color: scheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: FilledButton.icon(
              onPressed: onOpenChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Message worker'),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _EmployerJobLoadingView extends StatelessWidget {
  const _EmployerJobLoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          pinned: true,
          expandedHeight: 360,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreenDark,
                    AppTheme.primaryGreen,
                    AppTheme.teal,
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == 3 ? 0 : AppSpacing.md,
                ),
                child: Widgets.shimmerLoader(height: index == 0 ? 170 : 145),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmployerJobStateView extends StatelessWidget {
  const _EmployerJobStateView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
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
                    child: Icon(icon, size: 31),
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
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.maybePop(context);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Go back'),
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

class _JobStatusVisual {
  const _JobStatusVisual({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_JobStatusVisual _statusVisual(String status) {
  switch (status) {
    case 'hired':
      return const _JobStatusVisual(
        label: 'Hired',
        color: AppTheme.info,
        icon: Icons.how_to_reg_rounded,
      );
    case 'in_progress':
      return const _JobStatusVisual(
        label: 'Active',
        color: AppTheme.teal,
        icon: Icons.play_circle_outline_rounded,
      );
    case 'completed':
      return const _JobStatusVisual(
        label: 'Completed',
        color: AppTheme.success,
        icon: Icons.task_alt_rounded,
      );
    case 'cancelled':
      return const _JobStatusVisual(
        label: 'Cancelled',
        color: AppTheme.error,
        icon: Icons.cancel_outlined,
      );
    case 'closed':
      return const _JobStatusVisual(
        label: 'Closed',
        color: AppTheme.warning,
        icon: Icons.lock_outline_rounded,
      );
    default:
      return const _JobStatusVisual(
        label: 'Open',
        color: AppTheme.success,
        icon: Icons.radio_button_checked_rounded,
      );
  }
}

String _formatAmount(double amount) {
  return NumberFormat('#,##0').format(amount);
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'W';

  return parts.map((part) => part[0].toUpperCase()).join();
}
