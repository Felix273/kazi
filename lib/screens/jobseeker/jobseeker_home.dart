import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/job_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

final userLocationProvider = FutureProvider.autoDispose<Position>((ref) async {
  return LocationService.getCurrentLocation();
});

final nearbyJobsProvider = FutureProvider.autoDispose<List<JobModel>>((
  ref,
) async {
  final position = await ref.watch(userLocationProvider.future);
  final radius = ref.watch(jobRadiusProvider);
  final category = ref.watch(selectedCategoryProvider);

  return JobService.getNearbyJobs(
    latitude: position.latitude,
    longitude: position.longitude,
    radiusInKm: radius,
    category: category == 'All' ? null : category,
  );
});

final jobRadiusProvider = StateProvider.autoDispose<double>(
  (ref) => AppConstants.defaultSearchRadius,
);

final selectedCategoryProvider = StateProvider.autoDispose<String>(
  (ref) => 'All',
);

class JobSeekerHomeScreen extends ConsumerStatefulWidget {
  const JobSeekerHomeScreen({super.key});

  @override
  ConsumerState<JobSeekerHomeScreen> createState() =>
      _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends ConsumerState<JobSeekerHomeScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSearchRadius();
  }

  Future<void> _restoreSearchRadius() async {
    final preferences = await SharedPreferences.getInstance();
    final radius = preferences.getDouble(AppConstants.prefSearchRadius);

    if (!mounted ||
        radius == null ||
        !AppConstants.searchRadii.contains(radius)) {
      return;
    }

    ref.read(jobRadiusProvider.notifier).state = radius;
  }

  Future<void> _refreshJobs() async {
    ref.invalidate(userLocationProvider);
    ref.invalidate(nearbyJobsProvider);

    try {
      await ref.read(nearbyJobsProvider.future);
    } catch (_) {
      // The dashboard error state communicates refresh failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(nearbyJobsProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final selectedRadius = ref.watch(jobRadiusProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final jobs = jobsAsync.asData?.value ?? const <JobModel>[];
    final urgentJobs = jobs.where((job) => job.isUrgent).length;

    return Scaffold(
      bottomNavigationBar: Widgets.bottomNav(
        currentIndex: 0,
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
      body: RefreshIndicator(
        onRefresh: _refreshJobs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: true,
              toolbarHeight: 0,
              expandedHeight: 312,
              backgroundColor: AppTheme.primaryGreenDark,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _DiscoveryHero(
                  radius: selectedRadius,
                  matchCount: jobs.length,
                  urgentCount: urgentJobs,
                  locationReady: locationAsync.asData != null,
                  onRadiusPressed: _showRadiusSheet,
                  onRefreshPressed: () {
                    _refreshJobs();
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
                  AppSpacing.sm,
                ),
                child: Widgets.sectionHeader(
                  context: context,
                  title: 'Browse by category',
                  subtitle: 'Choose the work that matches your skills.',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.jobCategories.take(9).length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final category = index == 0
                        ? 'All'
                        : AppConstants.jobCategories[index - 1];

                    return _CategoryChip(
                      label: category,
                      icon: index == 0
                          ? Icons.apps_rounded
                          : _categoryIcon(category),
                      isSelected: selectedCategory == category,
                      onSelected: () {
                        ref.read(selectedCategoryProvider.notifier).state =
                            category;
                      },
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Widgets.sectionHeader(
                  context: context,
                  title: selectedCategory == 'All'
                      ? 'Jobs near you'
                      : '$selectedCategory jobs',
                  subtitle:
                      'Showing opportunities within '
                      '${selectedRadius.toStringAsFixed(0)} km.',
                  actionLabel: 'Radius',
                  onAction: _showRadiusSheet,
                ),
              ),
            ),
            _buildJobsSliver(jobsAsync),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsSliver(AsyncValue<List<JobModel>> jobsAsync) {
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _DashboardStateCard(
                icon: Icons.travel_explore_rounded,
                title: 'No matching jobs yet',
                message:
                    'Try another category or increase your search radius '
                    'to discover more opportunities.',
                actionLabel: 'Change radius',
                onAction: _showRadiusSheet,
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

              return _JobCardWidget(job: job, jobId: job.id);
            }, childCount: jobs.length * 2 - 1),
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : AppSpacing.md),
              child: Widgets.shimmerLoader(height: 220),
            ),
            childCount: 3,
          ),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _DashboardStateCard(
            icon: Icons.location_off_rounded,
            title: 'Nearby jobs are unavailable',
            message:
                'Check your location permission and internet connection, '
                'then refresh the dashboard.',
            actionLabel: 'Try again',
            onAction: () {
              _refreshJobs();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showRadiusSheet() async {
    final currentRadius = ref.read(jobRadiusProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                'Search distance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose how far Kazi should search from your live location.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...AppConstants.searchRadii.map((radius) {
                final isSelected = radius == currentRadius;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: scheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      foregroundColor: isSelected
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                      child: const Icon(Icons.near_me_rounded),
                    ),
                    title: Text(
                      '${radius.toStringAsFixed(0)} km',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      radius >= 50
                          ? 'Wider city-wide search'
                          : 'Jobs within ${radius.toStringAsFixed(0)} km',
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: scheme.primary,
                          )
                        : null,
                    onTap: () async {
                      ref.read(jobRadiusProvider.notifier).state = radius;

                      final preferences = await SharedPreferences.getInstance();

                      await preferences.setDouble(
                        AppConstants.prefSearchRadius,
                        radius,
                      );

                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                );
              }),
              ],
              ),
              ),
            );
          },
        );
    }
  }

class _DiscoveryHero extends StatelessWidget {
  const _DiscoveryHero({
    required this.radius,
    required this.matchCount,
    required this.urgentCount,
    required this.locationReady,
    required this.onRadiusPressed,
    required this.onRefreshPressed,
  });

  final double radius;
  final int matchCount;
  final int urgentCount;
  final bool locationReady;
  final VoidCallback onRadiusPressed;
  final VoidCallback onRefreshPressed;

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
            right: -56,
            top: 22,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 28),
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
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'KAZI DISCOVER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Refresh nearby jobs',
                        onPressed: onRefreshPressed,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Work near you.',
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
                    'Trusted local opportunities, matched to your location.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _HeroActionPill(
                        icon: locationReady
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        label: locationReady
                            ? 'Within ${radius.toStringAsFixed(0)} km'
                            : 'Finding location',
                        onTap: onRadiusPressed,
                      ),
                      _HeroActionPill(
                        icon: Icons.tune_rounded,
                        label: 'Adjust search',
                        onTap: onRadiusPressed,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          value: '$matchCount',
                          label: 'Nearby matches',
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _HeroMetric(
                          value: '$urgentCount',
                          label: 'Urgent today',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionPill extends StatelessWidget {
  const _HeroActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
    );
  }
}

class _JobCardWidget extends StatelessWidget {
  const _JobCardWidget({required this.job, required this.jobId});

  final JobModel job;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final durationLabel = job.durationType == 'hours'
        ? '${job.duration} hour${job.duration == 1 ? '' : 's'}'
        : '${job.duration} day${job.duration == 1 ? '' : 's'}';
    final workScopeLabel = '${job.estimatedHours.toStringAsFixed(1)}h · ${job.workerCount} ${job.workerCount == 1 ? 'worker' : 'workers'}';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/jobseeker/job/$jobId'),
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
                        if (job.isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'URGENT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          job.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${job.employerName} • ${job.neighborhood}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _MetaPill(
                    icon: Icons.near_me_outlined,
                    label: '${(job.distanceKm ?? 0).toStringAsFixed(1)} km',
                  ),
                  _MetaPill(icon: Icons.schedule_rounded, label: durationLabel),
                  _MetaPill(icon: Icons.people_outline, label: workScopeLabel),
                  _MetaPill(
                    icon: Icons.calendar_today_outlined,
                    label: '${job.startDate.day}/${job.startDate.month}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TAKE-HOME PAY',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'KES ${job.workerEarns.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Job value: KES '
                          '${job.salaryKES.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      _showApplyDialog(context, jobId, job.title);
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, String jobId, String jobTitle) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.assignment_turned_in_outlined),
          title: const Text('Apply for this job?'),
          content: Text(
            'Submit your application for “$jobTitle”? '
            'The employer will be notified immediately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _createApplication(context, jobId);
              },
              child: const Text('Submit application'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createApplication(BuildContext context, String jobId) async {
    try {
      await ApplicationService.instance.applyToJob(jobId: jobId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStateCard extends StatelessWidget {
  const _DashboardStateCard({
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
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.tune_rounded),
              label: Text(actionLabel),
            ),
          ],
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
