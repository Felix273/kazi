import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../utils/app_theme.dart';

enum KaziBrandVariant { iconOnly, compact, full }

class KaziBrand extends StatelessWidget {
  const KaziBrand({
    super.key,
    this.markSize = 48,
    this.inverted = false,
    this.showTagline = false,
    this.centered = false,
    this.variant = KaziBrandVariant.compact,
  });

  final double markSize;
  final bool inverted;
  final bool showTagline;
  final bool centered;
  final KaziBrandVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final primaryText = inverted ? Colors.white : scheme.onSurface;
    final secondaryText = inverted
        ? Colors.white.withValues(alpha: 0.7)
        : scheme.onSurfaceVariant;

    final brandMark = _BrandMark(size: markSize, inverted: inverted);

    if (variant == KaziBrandVariant.iconOnly) {
      return Semantics(
        label: AppConstants.appName,
        image: true,
        child: brandMark,
      );
    }

    final brandText = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: primaryText,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
            height: 1,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            AppConstants.tagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ],
    );

    final child = variant == KaziBrandVariant.full
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              brandMark,
              SizedBox(height: markSize * 0.22),
              brandText,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              brandMark,
              SizedBox(width: markSize * 0.28),
              brandText,
            ],
          );

    return Semantics(
      label: '${AppConstants.appName}. ${AppConstants.tagline}',
      image: true,
      child: child,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.inverted});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.055),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: inverted
              ? Colors.white.withValues(alpha: 0.16)
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: inverted ? 0.22 : 0.09),
            blurRadius: size * 0.36,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/kazi_brand.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) {
            return DecoratedBox(
              decoration: const BoxDecoration(color: AppTheme.primaryGreenDark),
              child: Icon(
                Icons.work_rounded,
                color: AppTheme.accentGold,
                size: size * 0.48,
              ),
            );
          },
        ),
      ),
    );
  }
}
