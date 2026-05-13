import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/jobs_bloc.dart';
import '../models/job_model.dart';
import '../widgets/job_card.dart';

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});
  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  String _selectedCategory = 'all';
  final _categories = [
    ('all', 'All'),
    ('manual', 'Manual'),
    ('professional', 'Pro Services'),
    ('errands', 'Errands'),
    ('digital', 'Digital'),
  ];

  @override
  void initState() {
    super.initState();
    // Load initial jobs
    context.read<JobsBloc>().add(LoadJobsEvent(category: _selectedCategory));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;
    final isEmployer = user?.isEmployer ?? false;

    return Scaffold(
      backgroundColor: KaziTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: KaziTheme.surface,
            elevation: 0,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: KaziTheme.surface,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.firstName.isNotEmpty == true ? user!.firstName : 'there'}! 👋',
                              style: KaziText.caption,
                            ),
                            Text('Find your next job', style: KaziText.h3),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: KaziTheme.surfaceWarm,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: KaziTheme.border),
                            ),
                            child: const Icon(Icons.notifications_outlined, color: KaziTheme.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: KaziTheme.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: KaziTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KaziTheme.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search_rounded, color: KaziTheme.textHint, size: 18),
                      const SizedBox(width: 8),
                      Text('Search jobs, skills...', style: KaziText.caption.copyWith(color: KaziTheme.textHint)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: KaziTheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: _categories.map((cat) {
                    final (id, label) = cat;
                    final isSelected = _selectedCategory == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = id);
                          // Reload jobs with new category
                          context.read<JobsBloc>().add(LoadJobsEvent(category: _selectedCategory));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? KaziTheme.primary : KaziTheme.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? KaziTheme.primary : KaziTheme.border,
                            ),
                          ),
                          child: Text(label, style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : KaziTheme.textSecondary,
                          )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          BlocBuilder<JobsBloc, JobsState>(
            builder: (context, state) {
              if (state is JobsLoadingState) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state is JobsErrorState) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      state.message,
                      style: KaziText.body.copyWith(color: KaziTheme.error),
                    ),
                  ),
                );
              } else if (state is JobsLoadedState || state is JobsRefreshingState) {
                final jobs = state is JobsLoadedState ? state.jobs : (state as JobsRefreshingState).currentJobs;
                
                if (jobs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_outline, size: 48, color: KaziTheme.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs found',
                            style: KaziText.h3.copyWith(color: KaziTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or check back later',
                            style: KaziText.body.copyWith(color: KaziTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final job = jobs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: KaziSpacing.md),
                        child: JobCard(
                          jobId: job.id,
                          title: job.title,
                          category: job.category,
                          budget: job.budget?.toDouble() ?? 0.0,
                          locationAddress: job.locationAddress,
                          durationDisplay: '${job.durationValue} ${job.durationUnit}',
                          employerName: job.employerName,
                          distanceKm: job.distanceKm?.toDouble() ?? 0.0,
                          isVerifiedEmployer: job.isVerifiedEmployer,
                          postedAgo: job.postedAgo,
                        ),
                      );
                    },
                    childCount: jobs.length,
                  ),
                );
              } else {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: isEmployer
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/post-job'),
              backgroundColor: KaziTheme.accent,
              elevation: 2,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Post a Job', style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700, color: Colors.white,
              )),
            )
          : null,
    );
  }
}
