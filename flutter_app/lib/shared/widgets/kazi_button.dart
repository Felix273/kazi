import 'package:flutter/material.dart';
import '../../core/theme.dart';

class KaziButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;

  const KaziButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _child,
      );
    }
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? KaziTheme.primary,
      ),
      child: _child,
    );
  }

  Widget get _child {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

/// Small loading shimmer for lists
class KaziShimmerCard extends StatelessWidget {
  const KaziShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: KaziSpacing.md),
      decoration: BoxDecoration(
        color: KaziTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Empty state widget
class KaziEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const KaziEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KaziSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: KaziTheme.surfaceWarm,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: KaziTheme.textHint),
            ),
            const SizedBox(height: KaziSpacing.lg),
            Text(title, style: KaziText.h3, textAlign: TextAlign.center),
            const SizedBox(height: KaziSpacing.sm),
            Text(subtitle, style: KaziText.body, textAlign: TextAlign.center),
            if (buttonLabel != null && onButtonTap != null) ...[
              const SizedBox(height: KaziSpacing.xl),
              SizedBox(
                width: 200,
                child: KaziButton(label: buttonLabel!, onPressed: onButtonTap),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
