import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isBookmarked = false;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: _JobDetailLoadingView());
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: _JobDetailStateView(
              icon: Icons.cloud_off_rounded,
              title: 'Job is unavailable',
              message:
                  'Check your internet connection and try loading this opportunity again.',
            ),
          );
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const Scaffold(
            body: _JobDetailStateView(
              icon: Icons.work_off_outlined,
              title: 'Job no longer available',
              message:
                  'This opportunity may have been filled, closed, or removed by the employer.',
            ),
          );
        }

        final job = JobModel.fromMap(document.data()!, document.id);

        final workerEarns = job.workerEarns;

        return Scaffold(
          bottomNavigationBar: _JobApplicationBar(
            workerEarns: workerEarns,
            isApplying: _isApplying,
            onApply: () => _showApplyDialog(job),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 360,
                backgroundColor: AppTheme.primaryGreenDark,
                foregroundColor: Colors.white,
                title: const Text('Job details'),
                actions: [
                  IconButton(
                    tooltip: _isBookmarked ? 'Remove saved job' : 'Save job',
                    onPressed: () {
                      setState(() {
                        _isBookmarked = !_isBookmarked;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isBookmarked
                                ? 'Job saved.'
                                : 'Job removed from saved jobs.',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      _isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: _JobHero(job: job),
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
                  child: _JobFactsCard(job: job),
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
                  child: _JobSectionCard(
                    icon: Icons.description_outlined,
                    title: 'About this job',
                    child: Text(
                      job.description.trim().isEmpty
                          ? 'The employer has not added a detailed description.'
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
                    child: _JobSectionCard(
                      icon: Icons.fact_check_outlined,
                      title: 'Requirements',
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < job.requirements.length;
                            index++
                          ) ...[
                            _RequirementRow(text: job.requirements[index]),
                            if (index < job.requirements.length - 1)
                              const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
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
                  child: _ApplicationInsightCard(
                    applicantCount: job.applicantCount,
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

  Future<void> _showApplyDialog(JobModel job) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.send_rounded, size: 28),
          ),
          title: const Text('Submit application?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your profile and current distance from the job will be shared with the employer.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Job budget: KES '
                      '${_formatAmount(job.salaryKES)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Estimated payout: KES '
                      '${_formatAmount(job.workerEarns)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isApplying = true);

    try {
      final currentPosition = await LocationService.getCurrentLocation();

      final distanceKm = LocationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        job.location.latitude,
        job.location.longitude,
      );

      await ApplicationService.instance.applyToJob(
        jobId: widget.jobId,
        distanceKm: distanceKm,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your application has been submitted successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your application could not be submitted. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}

class _JobHero extends StatelessWidget {
  const _JobHero({required this.job});

  final JobModel job;

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
            left: -50,
            bottom: -58,
            child: Container(
              width: 150,
              height: 150,
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
                        child: Icon(
                          _categoryIcon(job.category),
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
                      if (job.isUrgent) const _UrgentBadge(),
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
                        icon: Icons.schedule_rounded,
                        label: _timeAgo(job.createdAt),
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

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
          SizedBox(width: AppSpacing.xxs),
          Text(
            'Urgent',
            style: TextStyle(
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

class _JobFactsCard extends StatelessWidget {
  const _JobFactsCard({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final durationLabel = job.durationType == 'hours'
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
                    icon: Icons.timelapse_rounded,
                    label: 'Duration',
                    value: durationLabel,
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
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: job.neighborhood,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _JobFact(
                    icon: Icons.payments_outlined,
                    label: 'Your payout',
                    value: 'KES ${_formatAmount(job.workerEarns)}',
                    highlighted: true,
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
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: highlighted
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          foregroundColor: highlighted
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
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
                  color: highlighted ? scheme.primary : null,
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

class _JobSectionCard extends StatelessWidget {
  const _JobSectionCard({
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
  const _RequirementRow({required this.text});

  final String text;

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
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _ApplicationInsightCard extends StatelessWidget {
  const _ApplicationInsightCard({required this.applicantCount});

  final int applicantCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: const Icon(Icons.groups_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$applicantCount applicant'
                  '${applicantCount == 1 ? '' : 's'} so far',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  applicantCount == 0
                      ? 'Apply early and make a strong first impression.'
                      : 'A complete profile can help your application stand out.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    height: 1.4,
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

class _JobApplicationBar extends StatelessWidget {
  const _JobApplicationBar({
    required this.workerEarns,
    required this.isApplying,
    required this.onApply,
  });

  final double workerEarns;
  final bool isApplying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                      'ESTIMATED PAYOUT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'KES ${_formatAmount(workerEarns)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: isApplying ? null : onApply,
                icon: isApplying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(isApplying ? 'Applying…' : 'Apply now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobDetailLoadingView extends StatelessWidget {
  const _JobDetailLoadingView();

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

class _JobDetailStateView extends StatelessWidget {
  const _JobDetailStateView({
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
                    onPressed: () => Navigator.maybePop(context),
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

String _timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  if (difference.inDays == 1) {
    return 'Yesterday';
  }

  return '${difference.inDays} days ago';
}

String _formatAmount(double amount) {
  return NumberFormat('#,##0').format(amount);
}
