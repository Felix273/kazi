import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../shared/widgets/kazi_button.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;
    final isWorker = user?.isWorker ?? false;

    // TODO: Wire up JobDetailBloc to fetch real job data
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KaziSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category + status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Manual Labour',
                    style: TextStyle(
                      fontFamily: 'Sora', fontSize: 12,
                      fontWeight: FontWeight.w600, color: Color(0xFFEA580C),
                    )),
                ),
                const SizedBox(width: KaziSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: KaziTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Open',
                    style: TextStyle(
                      fontFamily: 'Sora', fontSize: 12,
                      fontWeight: FontWeight.w600, color: KaziTheme.info,
                    )),
                ),
              ],
            ),

            const SizedBox(height: KaziSpacing.md),
            Text('House Cleaning — 3 Bedroom', style: KaziText.h2),
            const SizedBox(height: KaziSpacing.sm),

            // Meta row
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: KaziTheme.textSecondary),
                const SizedBox(width: 4),
                Text('Kilimani, Nairobi', style: KaziText.caption),
                const SizedBox(width: KaziSpacing.md),
                const Icon(Icons.schedule_rounded, size: 14, color: KaziTheme.textSecondary),
                const SizedBox(width: 4),
                Text('4 hours', style: KaziText.caption),
                const SizedBox(width: KaziSpacing.md),
                const Icon(Icons.access_time, size: 14, color: KaziTheme.textSecondary),
                const SizedBox(width: 4),
                Text('2m ago', style: KaziText.caption),
              ],
            ),

            const SizedBox(height: KaziSpacing.lg),

            // Budget card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(KaziSpacing.md),
              decoration: BoxDecoration(
                color: KaziTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KaziTheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: KaziText.label),
                  const SizedBox(height: 4),
                  const Text('KES 2,500',
                    style: TextStyle(
                      fontFamily: 'Sora', fontSize: 28,
                      fontWeight: FontWeight.w700, color: KaziTheme.primary,
                    )),
                  Text('Negotiable', style: KaziText.caption),
                ],
              ),
            ),

            const SizedBox(height: KaziSpacing.lg),

            // Description
            Text('Description', style: KaziText.h3),
            const SizedBox(height: KaziSpacing.sm),
            Text(
              'Looking for an experienced cleaner to clean my 3-bedroom apartment in Kilimani. '
              'All cleaning supplies will be provided. The job includes vacuuming, mopping, '
              'bathroom cleaning, and kitchen cleaning. Please bring your own gloves.',
              style: KaziText.body,
            ),

            const SizedBox(height: KaziSpacing.lg),

            // Employer card
            Text('Posted by', style: KaziText.h3),
            const SizedBox(height: KaziSpacing.sm),
            Container(
              padding: const EdgeInsets.all(KaziSpacing.md),
              decoration: BoxDecoration(
                color: KaziTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KaziTheme.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: KaziTheme.surfaceWarm,
                    child: Text('J', style: TextStyle(
                      fontFamily: 'Sora', fontWeight: FontWeight.w600,
                      color: KaziTheme.textSecondary,
                    )),
                  ),
                  const SizedBox(width: KaziSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('John M.', style: KaziText.bodyMedium),
                            SizedBox(width: 4),
                            Icon(Icons.verified_rounded, size: 14, color: KaziTheme.info),
                          ],
                        ),
                        Text('4.8 ★  ·  12 jobs posted', style: KaziText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: KaziSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(KaziSpacing.md),
        child: isWorker
            ? KaziButton(
                label: 'Apply for this Job',
                onPressed: () => _showApplySheet(context),
              )
            : KaziButton(
                label: 'View Applications (3)',
                onPressed: () => context.push('/jobs/$jobId/applications'),
              ),
      ),
    );
  }

  void _showApplySheet(BuildContext context) {
    final coverCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: KaziTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          KaziSpacing.lg, KaziSpacing.lg,
          KaziSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + KaziSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apply for this Job', style: KaziText.h3),
            const SizedBox(height: KaziSpacing.sm),
            Text('Add a short message to stand out (optional)', style: KaziText.body),
            const SizedBox(height: KaziSpacing.md),
            TextField(
              controller: coverCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. I have 3 years of cleaning experience and can start immediately...',
              ),
            ),
            const SizedBox(height: KaziSpacing.lg),
            KaziButton(
              label: 'Send Application',
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Application sent!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
