import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class UserRatingWidget extends StatelessWidget {
  const UserRatingWidget({
    super.key,
    required this.userName,
    this.userPhotoUrl = '',
    required this.rating,
    this.totalRatings = 0,
  });

  final String userName;
  final String userPhotoUrl;
  final double rating;
  final int totalRatings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo = userPhotoUrl.trim();
    final normalizedRating = rating.clamp(0.0, 5.0).toDouble();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
              child: photo.isEmpty
                  ? Text(
                      _initials(userName),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xxs),
                          child: Icon(
                            _starIcon(index: index, rating: normalizedRating),
                            size: 17,
                            color: index < normalizedRating.ceil()
                                ? AppTheme.accentGold
                                : scheme.outlineVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        normalizedRating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                totalRatings == 0
                    ? 'No reviews'
                    : '$totalRatings '
                          '${totalRatings == 1 ? 'review' : 'reviews'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _starIcon({required int index, required double rating}) {
  final position = index + 1;

  if (rating >= position) {
    return Icons.star_rounded;
  }

  if (rating > index && rating < position) {
    return Icons.star_half_rounded;
  }

  return Icons.star_border_rounded;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'U';

  return parts.map((part) => part[0].toUpperCase()).join();
}
