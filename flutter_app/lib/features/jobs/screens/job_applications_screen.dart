import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/kazi_button.dart';

class JobApplicationsScreen extends StatelessWidget {
  final String jobId;
  const JobApplicationsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up JobApplicationsBloc
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(title: const Text('Applications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KaziSpacing.md),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: KaziSpacing.md),
        itemBuilder: (context, i) => _ApplicationCard(
          name: ['Grace K.', 'Peter M.', 'Amina W.'][i],
          rating: [4.9, 4.6, 4.8][i],
          totalJobs: [34, 12, 28][i],
          isVerified: [true, false, true][i],
          coverNote: i == 0
              ? 'I have 5 years of professional cleaning experience. I can start immediately.'
              : null,
          jobId: jobId,
          applicationId: 'app_$i',
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final String name;
  final double rating;
  final int totalJobs;
  final bool isVerified;
  final String? coverNote;
  final String jobId;
  final String applicationId;

  const _ApplicationCard({
    required this.name,
    required this.rating,
    required this.totalJobs,
    required this.isVerified,
    this.coverNote,
    required this.jobId,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KaziSpacing.md),
      decoration: BoxDecoration(
        color: KaziTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KaziTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: KaziTheme.primary.withOpacity(0.1),
                child: Text(name[0], style: const TextStyle(
                  fontFamily: 'Sora', fontWeight: FontWeight.w700,
                  color: KaziTheme.primary, fontSize: 18,
                )),
              ),
              const SizedBox(width: KaziSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: KaziText.bodyMedium),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: KaziTheme.info),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: KaziTheme.accent),
                        const SizedBox(width: 2),
                        Text('$rating  ·  $totalJobs jobs done', style: KaziText.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (coverNote != null) ...[
            const SizedBox(height: KaziSpacing.md),
            Container(
              padding: const EdgeInsets.all(KaziSpacing.sm),
              decoration: BoxDecoration(
                color: KaziTheme.surfaceWarm,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(coverNote!, style: KaziText.body),
            ),
          ],

          const SizedBox(height: KaziSpacing.md),
          Row(
            children: [
              Expanded(
                child: KaziButton(
                  label: 'Accept',
                  onPressed: () => _acceptDialog(context),
                ),
              ),
              const SizedBox(width: KaziSpacing.sm),
              Expanded(
                child: KaziButton(
                  label: 'View Profile',
                  isOutlined: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _acceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hire this worker?', style: KaziText.h3),
        content: Text(
          'You\'re about to hire $name. A chat room will be created and '
          'you\'ll be prompted to secure payment via M-Pesa.',
          style: KaziText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: trigger AcceptApplicationBloc event
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name hired! Chat room created.'),
                  backgroundColor: KaziTheme.success,
                ),
              );
            },
            child: const Text('Hire'),
          ),
        ],
      ),
    );
  }
}
