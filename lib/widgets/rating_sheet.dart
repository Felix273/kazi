import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class RatingSheet extends StatefulWidget {
  const RatingSheet({
    super.key,
    required this.jobTitle,
    required this.onRatingChanged,
    required this.onCommentChanged,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final String jobTitle;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  State<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<RatingSheet> {
  int _selectedRating = 0;

  String get _ratingLabel => switch (_selectedRating) {
    1 => 'Very poor',
    2 => 'Below expectations',
    3 => 'Good',
    4 => 'Very good',
    5 => 'Excellent',
    _ => 'Select a rating',
  };

  String get _ratingDescription => switch (_selectedRating) {
    1 => 'The experience had serious problems.',
    2 => 'The experience did not fully meet expectations.',
    3 => 'The experience met the basic expectations.',
    4 => 'The experience was reliable and professional.',
    5 => 'The experience was exceptional from start to finish.',
    _ => 'Your review helps build trust across the Kazi community.',
  };

  void _selectRating(int rating) {
    if (widget.isSubmitting) return;

    setState(() {
      _selectedRating = rating;
    });

    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.secondaryContainer,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 35,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Job completed',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Share your experience with “${widget.jobTitle}”.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    'How was the experience?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      final selected = rating <= _selectedRating;

                      return Semantics(
                        button: true,
                        selected: selected,
                        label: '$rating star${rating == 1 ? '' : 's'}',
                        child: IconButton(
                          tooltip: '$rating star${rating == 1 ? '' : 's'}',
                          onPressed: widget.isSubmitting
                              ? null
                              : () {
                                  _selectRating(rating);
                                },
                          iconSize: 39,
                          visualDensity: VisualDensity.compact,
                          icon: AnimatedScale(
                            duration: AppMotion.standard,
                            scale: selected ? 1.08 : 1,
                            child: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: selected
                                  ? AppTheme.accentGold
                                  : scheme.outlineVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedSwitcher(
                    duration: AppMotion.standard,
                    child: Column(
                      key: ValueKey(_selectedRating),
                      children: [
                        Text(
                          _ratingLabel,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _selectedRating == 0
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _ratingDescription,
                          textAlign: TextAlign.center,
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
            const SizedBox(height: AppSpacing.md),
            TextField(
              enabled: !widget.isSubmitting,
              minLines: 4,
              maxLines: 6,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Comments',
                hintText:
                    'Add an optional comment about communication, quality, or professionalism.',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: Icon(Icons.rate_review_outlined),
                ),
              ),
              onChanged: widget.onCommentChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Reviews should be honest, respectful, and based only on this job experience.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: widget.isSubmitting || _selectedRating == 0
                  ? null
                  : widget.onSubmit,
              icon: widget.isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                widget.isSubmitting ? 'Submitting review…' : 'Submit review',
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _selectedRating == 0
                  ? 'Select a star rating to continue.'
                  : 'Your rating will appear on the user’s Kazi profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
