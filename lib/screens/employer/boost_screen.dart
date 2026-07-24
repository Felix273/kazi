import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/boost_service.dart';
import '../../utils/app_theme.dart';

enum BoostTier {
  basic(
    label: 'Basic',
    price: 50,
    duration: '6 hours',
    description: 'Move your job higher in nearby workers’ feeds.',
    reachLabel: 'Local visibility',
    icon: Icons.trending_up_rounded,
  ),
  standard(
    label: 'Standard',
    price: 100,
    duration: '24 hours',
    description:
        'Stay near the top of nearby opportunity feeds for a full day.',
    reachLabel: 'Extended reach',
    icon: Icons.rocket_launch_outlined,
  ),
  premium(
    label: 'Premium',
    price: 200,
    duration: '3 days',
    description:
        'Maximum placement plus a notification to relevant nearby workers.',
    reachLabel: 'Maximum reach',
    icon: Icons.auto_awesome_rounded,
  );

  const BoostTier({
    required this.label,
    required this.price,
    required this.duration,
    required this.description,
    required this.reachLabel,
    required this.icon,
  });

  final String label;
  final int price;
  final String duration;
  final String description;
  final String reachLabel;
  final IconData icon;

  String get priceLabel => 'KES $price';
}

class BoostScreen extends ConsumerStatefulWidget {
  const BoostScreen({
    super.key,
    required this.jobId,
    this.currentTier,
    this.boostExpiresAt,
  });

  final String jobId;
  final String? currentTier;
  final DateTime? boostExpiresAt;

  @override
  ConsumerState<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends ConsumerState<BoostScreen> {
  BoostTier? _selectedTier;
  bool _isBoosting = false;

  bool get _isAlreadyBoosted {
    final expiry = widget.boostExpiresAt;

    if (widget.currentTier == null) return false;
    if (expiry == null) return true;

    return expiry.isAfter(DateTime.now());
  }

  String get _normalizedCurrentTier =>
      widget.currentTier?.trim().toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _BoostActionBar(
        selectedTier: _selectedTier,
        isBoosting: _isBoosting,
        onBoost: _confirmBoost,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 310,
            backgroundColor: AppTheme.primaryGreenDark,
            foregroundColor: Colors.white,
            title: const Text('Boost job'),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _BoostHero(
                isAlreadyBoosted: _isAlreadyBoosted,
                currentTier: widget.currentTier,
                boostExpiresAt: widget.boostExpiresAt,
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
              child: _SectionIntroduction(isAlreadyBoosted: _isAlreadyBoosted),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tier = BoostTier.values[index];
                final isCurrentTier =
                    _normalizedCurrentTier == tier.label.toLowerCase();

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == BoostTier.values.length - 1
                        ? 0
                        : AppSpacing.md,
                  ),
                  child: _BoostTierCard(
                    tier: tier,
                    selected: _selectedTier == tier,
                    current: isCurrentTier && _isAlreadyBoosted,
                    onSelected: isCurrentTier && _isAlreadyBoosted
                        ? null
                        : () {
                            setState(() {
                              _selectedTier = tier;
                            });
                          },
                  ),
                );
              }, childCount: BoostTier.values.length),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: _BoostInformationCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Future<void> _confirmBoost() async {
    final tier = _selectedTier;

    if (tier == null || _isBoosting) return;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 32,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: Icon(tier.icon, size: 29),
          ),
          title: Text('Activate ${tier.label} boost?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your job will receive enhanced visibility for ${tier.duration}.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      tier.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      tier.priceLabel,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tier.reachLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (tier == BoostTier.premium) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 19,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Relevant nearby workers will also receive a job notification.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Activate boost'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBoosting = true);

    try {
      await BoostService.boostJob(
        jobId: widget.jobId,
        tier: tier.label,
        amount: tier.price,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tier.label} boost activated for ${tier.duration}.'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The job could not be boosted. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBoosting = false);
      }
    }
  }
}

class _BoostHero extends StatelessWidget {
  const _BoostHero({
    required this.isAlreadyBoosted,
    required this.currentTier,
    required this.boostExpiresAt,
  });

  final bool isAlreadyBoosted;
  final String? currentTier;
  final DateTime? boostExpiresAt;

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
            right: -58,
            top: 24,
            child: Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 29, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: -56,
            child: Container(
              width: 146,
              height: 146,
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
                        width: 49,
                        height: 49,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: AppTheme.accentGold,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'JOB VISIBILITY',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isAlreadyBoosted
                        ? 'Your job is getting noticed.'
                        : 'Reach more workers.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isAlreadyBoosted
                        ? 'Choose another plan when you need more reach.'
                        : 'Move your opportunity higher in nearby workers’ feeds.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  if (isAlreadyBoosted)
                    _ActiveBoostSummary(
                      currentTier: currentTier,
                      boostExpiresAt: boostExpiresAt,
                    )
                  else
                    const Row(
                      children: [
                        _HeroBenefit(
                          icon: Icons.visibility_outlined,
                          label: 'More views',
                        ),
                        SizedBox(width: AppSpacing.lg),
                        _HeroBenefit(
                          icon: Icons.groups_outlined,
                          label: 'More applicants',
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

class _ActiveBoostSummary extends StatelessWidget {
  const _ActiveBoostSummary({
    required this.currentTier,
    required this.boostExpiresAt,
  });

  final String? currentTier;
  final DateTime? boostExpiresAt;

  @override
  Widget build(BuildContext context) {
    final tier = currentTier?.trim().isEmpty ?? true
        ? 'Boost'
        : '${currentTier![0].toUpperCase()}'
              '${currentTier!.substring(1).toLowerCase()}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.primaryGreenDark,
            child: Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tier plan active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  boostExpiresAt == null
                      ? 'Currently receiving enhanced visibility'
                      : 'Expires ${_formatExpiry(boostExpiresAt!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.accentGold),
        ],
      ),
    );
  }
}

class _HeroBenefit extends StatelessWidget {
  const _HeroBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 19),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionIntroduction extends StatelessWidget {
  const _SectionIntroduction({required this.isAlreadyBoosted});

  final bool isAlreadyBoosted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAlreadyBoosted ? 'Extend your reach' : 'Choose your boost',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isAlreadyBoosted
              ? 'Select a different plan to continue promoting your job.'
              : 'Select the visibility level that matches how quickly you need applicants.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BoostTierCard extends StatelessWidget {
  const _BoostTierCard({
    required this.tier,
    required this.selected,
    required this.current,
    required this.onSelected,
  });

  final BoostTier tier;
  final bool selected;
  final bool current;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recommended = tier == BoostTier.standard;

    return Semantics(
      button: onSelected != null,
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.52)
              : scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? scheme.primary
                : current
                ? AppTheme.success
                : scheme.outlineVariant,
            width: selected || current ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onSelected,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 49,
                        height: 49,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? scheme.primary
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          tier.icon,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tier.label,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (recommended) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const _PlanBadge(
                                    label: 'Recommended',
                                    color: AppTheme.teal,
                                  ),
                                ],
                                if (current) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const _PlanBadge(
                                    label: 'Current',
                                    color: AppTheme.success,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              tier.reachLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedContainer(
                        duration: AppMotion.standard,
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? scheme.primary : Colors.transparent,
                          border: Border.all(
                            color: selected ? scheme.primary : scheme.outline,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: scheme.onPrimary,
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    tier.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      _TierDetail(
                        icon: Icons.schedule_rounded,
                        value: tier.duration,
                      ),
                      const Spacer(),
                      Text(
                        tier.priceLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (tier == BoostTier.premium) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 19,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Includes a targeted worker notification',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TierDetail extends StatelessWidget {
  const _TierDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BoostInformationCard extends StatelessWidget {
  const _BoostInformationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: const Icon(Icons.lightbulb_outline_rounded),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How boosting works',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Boosted jobs receive priority placement for workers searching near the job location. Results depend on worker availability and demand.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.5,
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

class _BoostActionBar extends StatelessWidget {
  const _BoostActionBar({
    required this.selectedTier,
    required this.isBoosting,
    required this.onBoost,
  });

  final BoostTier? selectedTier;
  final bool isBoosting;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tier = selectedTier;

    return Material(
      elevation: 9,
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
                      tier == null ? 'SELECT A PLAN' : tier.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      tier == null ? 'Choose a boost above' : tier.priceLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tier == null
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              FilledButton.icon(
                onPressed: tier == null || isBoosting ? null : onBoost,
                icon: isBoosting
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: Text(isBoosting ? 'Activating…' : 'Boost job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatExpiry(DateTime expiry) {
  final difference = expiry.difference(DateTime.now());

  if (difference.isNegative) {
    return 'soon';
  }

  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;

    return 'in $minutes minute'
        '${minutes == 1 ? '' : 's'}';
  }

  if (difference.inHours < 24) {
    final hours = difference.inHours;

    return 'in $hours hour'
        '${hours == 1 ? '' : 's'}';
  }

  final days = (difference.inHours / 24).ceil();

  return 'in $days day${days == 1 ? '' : 's'}';
}
