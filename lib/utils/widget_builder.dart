import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import 'app_theme.dart';

/// Reusable presentation components used throughout Kazi.
///
/// The class name is retained to avoid breaking existing screens while the
/// application is migrated to the unified design system.
abstract final class Widgets {
  /// Material 3 navigation for the job-seeker workspace.
  static Widget bottomNav({
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return NavigationBar(
      selectedIndex: currentIndex.clamp(0, 4),
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore_rounded),
          label: 'Discover',
          tooltip: 'Discover nearby jobs',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Applications',
          tooltip: 'View your applications',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Wallet',
          tooltip: 'View your wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Messages',
          tooltip: 'Open your messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
          tooltip: 'Open your profile',
        ),
      ],
    );
  }

  /// Polished empty state for lists, dashboards, and search results.
  static Widget emptyState({
    required String icon,
    required String title,
    String? subtitle,
    VoidCallback? onRetry,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 38, height: 1),
                      semanticsLabel: title,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Theme-aware shimmer loading placeholder.
  static Widget shimmerLoader({
    required double height,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scheme = theme.colorScheme;

        return Shimmer.fromColors(
          baseColor: isDark
              ? scheme.surfaceContainerHighest
              : const Color(0xFFE5EBE8),
          highlightColor: isDark
              ? scheme.surfaceContainerHigh
              : const Color(0xFFF6F8F7),
          child: Container(
            width: width ?? double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
            ),
          ),
        );
      },
    );
  }

  /// Theme-aware loading list.
  static Widget shimmerList({required int itemCount, double height = 112}) {
    return Builder(
      builder: (context) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) => shimmerLoader(height: height),
        );
      },
    );
  }

  /// SVG asset helper.
  static Widget svgIcon({
    required String assetName,
    double size = 24,
    Color? color,
    String? semanticsLabel,
  }) {
    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        'assets/images/$assetName',
        semanticsLabel: semanticsLabel,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }

  /// Centered progress indicator with optional status text.
  static Widget loadingIndicator({String? message}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                if (message != null && message.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Consistent heading for dashboard sections.
  static Widget sectionHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
