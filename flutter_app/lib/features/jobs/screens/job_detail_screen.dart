import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme.dart';
import '../../../core/services/api_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../shared/widgets/kazi_button.dart';
import '../bloc/job_detail_bloc.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JobDetailBloc(context.read<ApiClient>())
        ..add(FetchJobDetailEvent(jobId)),
      child: _JobDetailView(jobId: jobId),
    );
  }
}

class _JobDetailView extends StatelessWidget {
  final String jobId;
  const _JobDetailView({required this.jobId});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;
    final isWorker = user?.isWorker ?? false;

    return BlocConsumer<JobDetailBloc, JobDetailState>(
      listener: (context, state) {
        if (state is JobAppliedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application sent successfully!'), backgroundColor: KaziTheme.success),
          );
        } else if (state is JobDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: KaziTheme.error),
          );
        }
      },
      builder: (context, state) {
        if (state is JobDetailLoading || state is JobDetailInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is JobDetailError && state is! JobDetailLoaded) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.error)),
          );
        }

        final job = (state as JobDetailLoaded).job;
        final employer = job['employer_detail'] ?? {};
        final createdAt = DateTime.parse(job['created_at']);

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                  child: Text((job['category_display'] ?? job['category']).toString().toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEA580C),
                          )),
                    ),
                    const SizedBox(width: KaziSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: KaziTheme.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(job['status'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: KaziTheme.info,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: KaziSpacing.md),
                Text(job['title'], style: KaziText.h2),
                const SizedBox(height: KaziSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: KaziTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(job['location_address'], style: KaziText.caption),
                    const SizedBox(width: KaziSpacing.md),
                    const Icon(Icons.schedule_rounded, size: 14, color: KaziTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${job['duration_value']} ${job['duration_unit']}', style: KaziText.caption),
                    const SizedBox(width: KaziSpacing.md),
                    const Icon(Icons.access_time, size: 14, color: KaziTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(timeago.format(createdAt), style: KaziText.caption),
                  ],
                ),
                const SizedBox(height: KaziSpacing.lg),
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
                      Text('KES ${job['budget']}',
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: KaziTheme.primary,
                          )),
                      if (job['is_negotiable']) Text('Negotiable', style: KaziText.caption),
                    ],
                  ),
                ),
                const SizedBox(height: KaziSpacing.lg),
                Text('Description', style: KaziText.h3),
                const SizedBox(height: KaziSpacing.sm),
                Text(job['description'], style: KaziText.body),
                const SizedBox(height: KaziSpacing.lg),
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
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: KaziTheme.surfaceWarm,
                        backgroundImage: employer['profile_photo'] != null
                            ? NetworkImage(employer['profile_photo'])
                            : null,
                        child: employer['profile_photo'] == null
                            ? Text(employer['first_name'][0],
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontWeight: FontWeight.w600,
                                  color: KaziTheme.textSecondary,
                                ))
                            : null,
                      ),
                      const SizedBox(width: KaziSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${employer['first_name']} ${employer['last_name']}', style: KaziText.bodyMedium),
                                const SizedBox(width: 4),
                                if (employer['is_verified'])
                                  const Icon(Icons.verified_rounded, size: 14, color: KaziTheme.info),
                              ],
                            ),
                            Text('${employer['average_rating']} ★  ·  ${employer['total_jobs_posted'] ?? 0} jobs posted',
                                style: KaziText.caption),
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
                    label: job['has_applied'] == true ? 'Applied' : 'Apply for this Job',
                    onPressed: job['has_applied'] == true ? null : () => _showApplySheet(context, job['id']),
                    isLoading: state is JobApplying,
                  )
                : KaziButton(
                    label: 'View Applications (${job['application_count']})',
                    onPressed: () => context.push('/jobs/$jobId/applications'),
                  ),
          ),
        );
      },
    );
  }

  void _showApplySheet(BuildContext context, String jobId) {
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
          KaziSpacing.lg,
          KaziSpacing.lg,
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
                context.read<JobDetailBloc>().add(ApplyForJobEvent(
                      jobId: jobId,
                      coverNote: coverCtrl.text,
                    ));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
