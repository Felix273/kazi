import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';

class JobCard extends StatelessWidget {
  final String jobId, title, category, locationAddress, durationDisplay, employerName, postedAgo;
  final double budget;
  final double? distanceKm;
  final bool isVerifiedEmployer;
  final String? status;

  const JobCard({
    super.key, required this.jobId, required this.title, required this.category,
    required this.budget, required this.locationAddress, required this.durationDisplay,
    required this.employerName, this.distanceKm, this.isVerifiedEmployer = false,
    required this.postedAgo, this.status,
  });

  Color get _catColor {
    switch (category) {
      case 'manual': return KaziTheme.catManual;
      case 'professional': return KaziTheme.catPro;
      case 'errands': return KaziTheme.catErrands;
      case 'digital': return KaziTheme.catDigital;
      default: return KaziTheme.primary;
    }
  }

  String get _catLabel {
    switch (category) {
      case 'manual': return 'Manual Labour';
      case 'professional': return 'Professional';
      case 'errands': return 'Errands';
      case 'digital': return 'Digital';
      default: return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/$jobId'),
      child: Container(
        padding: const EdgeInsets.all(KaziSpacing.md),
        decoration: BoxDecoration(
          color: KaziTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KaziTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_catLabel, style: GoogleFonts.dmSans(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _catColor,
                  )),
                ),
                if (distanceKm != null)
                  Text('${distanceKm!.toStringAsFixed(1)} km away', style: KaziText.caption),
              ],
            ),
            const SizedBox(height: KaziSpacing.sm),
            Text(title, style: KaziText.h3.copyWith(fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 13, color: KaziTheme.textHint),
                const SizedBox(width: 3),
                Expanded(child: Text(locationAddress, style: KaziText.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 12),
                Icon(Icons.schedule_rounded, size: 13, color: KaziTheme.textHint),
                const SizedBox(width: 3),
                Text(durationDisplay, style: KaziText.caption),
              ],
            ),
            const SizedBox(height: KaziSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: KaziSpacing.md),
            Row(
              children: [
                Text('KES ${budget.toStringAsFixed(0)}', style: KaziText.price),
                const Spacer(),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: KaziTheme.primary,
                      child: Text(
                        employerName[0].toUpperCase(),
                        style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(employerName, style: KaziText.caption.copyWith(fontWeight: FontWeight.w600)),
                    if (isVerifiedEmployer) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.verified_rounded, size: 13, color: KaziTheme.primary),
                    ],
                    const SizedBox(width: 10),
                    Text(postedAgo, style: KaziText.caption),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
