import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/kazi_button.dart';
import '../bloc/job_applications_bloc.dart';

class JobApplicationsScreen extends StatelessWidget {
  final String jobId;
  const JobApplicationsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JobApplicationsBloc(context.read<ApiClient>())
        ..add(FetchJobApplicationsEvent(jobId)),
      child: _JobApplicationsView(jobId: jobId),
    );
  }
}

class _JobApplicationsView extends StatelessWidget {
  final String jobId;
  const _JobApplicationsView({required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobApplicationsBloc, JobApplicationsState>(
      listener: (context, state) {
        if (state is AcceptApplicationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Worker hired! Chat room created.'),
              backgroundColor: KaziTheme.success,
            ),
          );
          // Navigate to chat or back
          context.pop();
        } else if (state is JobApplicationsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: KaziTheme.error),
          );
        }
      },
      builder: (context, state) {
        if (state is JobApplicationsLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is JobApplicationsError && state is! JobApplicationsLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Applications')),
            body: Center(child: Text(state.error)),
          );
        }

        final applications = state is JobApplicationsLoaded
            ? state.applications
            : (state is AcceptApplicationLoading || state is AcceptApplicationSuccess)
                ? (context.read<JobApplicationsBloc>().state as JobApplicationsLoaded).applications
                : [];

        if (applications.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Applications')),
            body: const Center(child: Text('No applications yet.')),
          );
        }

        return Scaffold(
          backgroundColor: KaziTheme.background,
          appBar: AppBar(title: const Text('Applications')),
          body: ListView.separated(
            padding: const EdgeInsets.all(KaziSpacing.md),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: KaziSpacing.md),
            itemBuilder: (context, i) {
              final app = applications[i];
              final worker = app['worker_detail'];
              return _ApplicationCard(
                name: '${worker['first_name']} ${worker['last_name']}',
                rating: double.parse(worker['average_rating'].toString()),
                totalJobs: worker['total_jobs_completed'],
                isVerified: worker['is_verified'],
                coverNote: app['cover_note'],
                jobId: jobId,
                applicationId: app['id'],
                isLoading: state is AcceptApplicationLoading,
              );
            },
          ),
        );
      },
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
  final bool isLoading;

  const _ApplicationCard({
    required this.name,
    required this.rating,
    required this.totalJobs,
    required this.isVerified,
    this.coverNote,
    required this.jobId,
    required this.applicationId,
    this.isLoading = false,
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
                child: Text(name[0],
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                      color: KaziTheme.primary,
                      fontSize: 18,
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
          if (coverNote != null && coverNote!.isNotEmpty) ...[
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
                  onPressed: isLoading ? null : () => _acceptDialog(context),
                ),
              ),
              const SizedBox(width: KaziSpacing.sm),
              Expanded(
                child: KaziButton(
                  label: 'View Profile',
                  isOutlined: true,
                  onPressed: () => context.push('/profile/${worker['id']}'),
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
          "You're about to hire $name. A chat room will be created and you'll be prompted to secure payment via M-Pesa.",
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
              context.read<JobApplicationsBloc>().add(AcceptApplicationEvent(
                    jobId: jobId,
                    applicationId: applicationId,
                  ));
            },
            child: const Text('Hire'),
          ),
        ],
      ),
    );
  }
}
