import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../auth/bloc/auth_bloc.dart';
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
                        onTap: () => setState(() => _selectedCategory = id),
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

          SliverPadding(
            padding: const EdgeInsets.all(KaziSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: KaziSpacing.md),
                  child: JobCard(
                    jobId: 'job_$index',
                    title: index % 2 == 0 ? 'House Cleaning – 3 Bedroom' : 'Plumbing – Fix Kitchen Sink',
                    category: index % 2 == 0 ? 'manual' : 'professional',
                    budget: index % 2 == 0 ? 2500 : 1800,
                    locationAddress: index % 2 == 0 ? 'Kilimani, Nairobi' : 'Westlands, Nairobi',
                    durationDisplay: index % 2 == 0 ? '4 hours' : '2 hours',
                    employerName: index % 2 == 0 ? 'John M.' : 'Amina W.',
                    distanceKm: 1.2 + index * 0.8,
                    isVerifiedEmployer: index % 2 == 0,
                    postedAgo: '${index + 1}m ago',
                  ),
                ),
                childCount: 6,
              ),
            ),
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
