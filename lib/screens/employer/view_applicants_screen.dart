import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/job_model.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

final employerJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('jobs')
      .where('employerId', isEqualTo: userId)
      .where(
        'status',
        whereIn: ['open', 'payment_pending', 'hired', 'completed'],
      )
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => JobModel.fromMap(document.data(), document.id))
            .toList(),
      );
});

class ViewApplicantsScreen extends StatefulWidget {
  const ViewApplicantsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  State<ViewApplicantsScreen> createState() => _ViewApplicantsScreenState();
}

class _ViewApplicantsScreenState extends State<ViewApplicantsScreen> {
  String? _hiringApplicantId;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .snapshots(),
      builder: (context, jobSnapshot) {
        final jobData = jobSnapshot.data?.data();
        final jobTitle = jobData?['title'] as String? ?? 'Job applicants';

        return Scaffold(
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('jobId', isEqualTo: widget.jobId)
                .orderBy('appliedAt', descending: false)
                .snapshots(),
            builder: (context, applicationSnapshot) {
              if (applicationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return _ApplicantsLoadingView(jobTitle: jobTitle);
              }

              if (applicationSnapshot.hasError) {
                return _ApplicantsStateView(
                  jobTitle: jobTitle,
                  icon: Icons.cloud_off_rounded,
                  title: 'Applicants are unavailable',
                  message:
                      'Check your internet connection and try loading the applicant list again.',
                );
              }

              final applications =
                  applicationSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              final pendingCount = applications.where((document) {
                final status =
                    document.data()['status'] as String? ?? 'pending';

                return status == 'pending';
              }).length;

              final verifiedCount = applications.where((document) {
                return document.data()['isVerified'] == true;
              }).length;

              final nearbyCount = applications.where((document) {
                final distance =
                    (document.data()['distance'] as num?)?.toDouble() ??
                    double.infinity;

                return distance <= 5;
              }).length;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 286,
                    backgroundColor: AppTheme.primaryGreenDark,
                    foregroundColor: Colors.white,
                    title: const Text('Applicants'),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: _ApplicantsHero(
                        jobTitle: jobTitle,
                        totalCount: applications.length,
                        pendingCount: pendingCount,
                        verifiedCount: verifiedCount,
                        nearbyCount: nearbyCount,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Widgets.sectionHeader(
                        context: context,
                        title: 'Review candidates',
                        subtitle: applications.isEmpty
                            ? 'Applications will appear here as workers respond.'
                            : 'Compare trust, experience, skills, and distance before hiring.',
                      ),
                    ),
                  ),
                  if (applications.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: _EmptyApplicantsCard(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isOdd) {
                            return const SizedBox(height: AppSpacing.md);
                          }

                          final document = applications[index ~/ 2];

                          return ApplicantCard(
                            application: document.data(),
                            isProcessing: _isProcessing,
                            hiringApplicantId: _hiringApplicantId,
                            onHire: (applicantId) {
                              return _handleHire(
                                applicantId,
                                document.id,
                                document.data(),
                              );
                            },
                            onDecline: (applicantId) {
                              return _handleDecline(applicantId, document.id);
                            },
                          );
                        }, childCount: applications.length * 2 - 1),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxl),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleHire(
    String applicantId,
    String applicationId,
    Map<String, dynamic> application,
  ) async {
    final jobDocument = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();

    final job = jobDocument.data();

    if (job == null || !mounted) return;

    final employerPays =
        (job['employerPaysKES'] as num?)?.toDouble() ??
        ((job['salaryKES'] as num?)?.toDouble() ?? 0) * 1.10;

    final workerName = application['workerName'] as String? ?? 'this applicant';

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.how_to_reg_rounded, size: 28),
          ),
          title: Text('Hire $workerName?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'An M-Pesa payment prompt will be sent to your registered phone number.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL PAYMENT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'KES ${_formatAmount(employerPays)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'The applicant will be hired after payment is confirmed.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Not now'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.phone_iphone_rounded),
              label: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isProcessing = true;
      _hiringApplicantId = applicantId;
    });

    try {
      final employerId = FirebaseAuth.instance.currentUser?.uid;

      if (employerId == null) {
        throw StateError('Not authenticated.');
      }

      final employerDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(employerId)
          .get();

      final phone =
          employerDocument.data()?['phone'] as String? ??
          job['employerPhone'] as String? ??
          '';

      if (phone.isEmpty) {
        throw StateError('Add your M-Pesa phone number to your profile first.');
      }

      final result = await PaymentService.hireApplicant(
        jobId: widget.jobId,
        applicationId: applicationId,
        workerId: applicantId,
        phone: phone,
      );

      if (!mounted) return;

      final mockCompleted = result['status'] == 'mock_completed';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mockCompleted
                ? 'The applicant has been hired successfully.'
                : 'The M-Pesa prompt was sent. Confirm the payment on your phone.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );

      if (mockCompleted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _hiringApplicantId = null;
        });
      }
    }
  }

  Future<void> _handleDecline(String applicantId, String applicationId) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            child: const Icon(Icons.person_remove_outlined, size: 28),
          ),
          title: const Text('Decline application?'),
          content: Text(
            'This candidate will be marked unsuccessful for this job.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Keep applicant'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
            'status': 'declined',
            'declinedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The application has been declined.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The application could not be declined. Please try again.',
          ),
        ),
      );
    }
  }
}

class _ApplicantsHero extends StatelessWidget {
  const _ApplicantsHero({
    required this.jobTitle,
    required this.totalCount,
    required this.pendingCount,
    required this.verifiedCount,
    required this.nearbyCount,
  });

  final String jobTitle;
  final int totalCount;
  final int pendingCount;
  final int verifiedCount;
  final int nearbyCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
            AppTheme.teal,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -56,
            top: 24,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 28, color: Colors.white24),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                82,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CANDIDATE PIPELINE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    jobTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _ApplicantMetric(
                          value: '$totalCount',
                          label: 'Total',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _ApplicantMetric(
                          value: '$pendingCount',
                          label: 'Pending',
                          highlighted: true,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _ApplicantMetric(
                          value: '$verifiedCount',
                          label: 'Verified',
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _ApplicantMetric(
                          value: '$nearbyCount',
                          label: 'Within 5 km',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantMetric extends StatelessWidget {
  const _ApplicantMetric({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlighted ? AppTheme.accentGold : Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: Colors.white24);
  }
}

class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.application,
    required this.isProcessing,
    required this.hiringApplicantId,
    required this.onHire,
    required this.onDecline,
  });

  final Map<String, dynamic> application;
  final bool isProcessing;
  final String? hiringApplicantId;
  final Future<void> Function(String) onHire;
  final Future<void> Function(String) onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final workerId = application['workerId'] as String? ?? '';
    final workerName = application['workerName'] as String? ?? 'Applicant';
    final workerPhoto = application['workerPhoto'] as String? ?? '';
    final workerRating = (application['workerRating'] as num?)?.toDouble() ?? 0;
    final neighborhood =
        application['workerNeighborhood'] as String? ?? 'Location not provided';
    final distance = (application['distance'] as num?)?.toDouble() ?? 0;
    final completedJobs =
        (application['totalJobsCompleted'] as num?)?.toInt() ?? 0;
    final skills = List<String>.from(application['skills'] ?? []);
    final bio = application['bio'] as String? ?? '';
    final verified = application['isVerified'] == true;
    final status = application['status'] as String? ?? 'pending';
    final appliedAt = (application['appliedAt'] as Timestamp?)?.toDate();

    final statusVisual = _applicationStatus(status);
    final isHiringThisApplicant = isProcessing && hiringApplicantId == workerId;
    final canDecide = status == 'pending';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  backgroundImage: workerPhoto.isEmpty
                      ? null
                      : NetworkImage(workerPhoto),
                  child: workerPhoto.isEmpty
                      ? Text(
                          _initials(workerName),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              workerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: AppSpacing.xxs),
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: AppTheme.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 17,
                            color: AppTheme.accentGold,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            workerRating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (appliedAt != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '• ${_timeAgo(appliedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ApplicantStatusBadge(status: statusVisual),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _ApplicantFact(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: neighborhood,
                  ),
                ),
                Container(width: 1, height: 42, color: scheme.outlineVariant),
                Expanded(
                  child: _ApplicantFact(
                    icon: Icons.directions_walk_rounded,
                    label: 'Distance',
                    value: '${distance.toStringAsFixed(1)} km',
                  ),
                ),
                Container(width: 1, height: 42, color: scheme.outlineVariant),
                Expanded(
                  child: _ApplicantFact(
                    icon: Icons.task_alt_rounded,
                    label: 'Jobs',
                    value: '$completedJobs',
                  ),
                ),
              ],
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                'SKILLS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: skills
                    .take(6)
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (bio.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                bio.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            if (canDecide)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      onPressed: isProcessing
                          ? null
                          : () => onDecline(workerId),
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : () => onHire(workerId),
                      icon: isHiringThisApplicant
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.how_to_reg_rounded),
                      label: Text(isHiringThisApplicant ? 'Hiring…' : 'Hire'),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: statusVisual.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(statusVisual.icon, color: statusVisual.color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        statusVisual.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusVisual.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantFact extends StatelessWidget {
  const _ApplicantFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Icon(icon, size: 19, color: scheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantStatusBadge extends StatelessWidget {
  const _ApplicantStatusBadge({required this.status});

  final _ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyApplicantsCard extends StatelessWidget {
  const _EmptyApplicantsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.group_add_outlined, size: 31),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No applications yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Workers who apply for this job will appear here for review.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantsLoadingView extends StatelessWidget {
  const _ApplicantsLoadingView({required this.jobTitle});

  final String jobTitle;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 286,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _ApplicantsHero(
              jobTitle: jobTitle,
              totalCount: 0,
              pendingCount: 0,
              verifiedCount: 0,
              nearbyCount: 0,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == 2 ? 0 : AppSpacing.md,
                ),
                child: Widgets.shimmerLoader(height: 290),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicantsStateView extends StatelessWidget {
  const _ApplicantsStateView({
    required this.jobTitle,
    required this.icon,
    required this.title,
    required this.message,
  });

  final String jobTitle;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 286,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _ApplicantsHero(
              jobTitle: jobTitle,
              totalCount: 0,
              pendingCount: 0,
              verifiedCount: 0,
              nearbyCount: 0,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: scheme.errorContainer,
                      foregroundColor: scheme.onErrorContainer,
                      child: Icon(icon, size: 31),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicationStatus {
  const _ApplicationStatus({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String label;
  final String message;
  final Color color;
  final IconData icon;
}

_ApplicationStatus _applicationStatus(String status) {
  switch (status) {
    case 'payment_pending':
      return const _ApplicationStatus(
        label: 'Payment',
        message: 'Payment confirmation is pending for this applicant.',
        color: AppTheme.info,
        icon: Icons.payments_outlined,
      );
    case 'accepted':
    case 'hired':
      return const _ApplicationStatus(
        label: 'Hired',
        message: 'This applicant has been selected for the job.',
        color: AppTheme.success,
        icon: Icons.how_to_reg_rounded,
      );
    case 'declined':
      return const _ApplicationStatus(
        label: 'Declined',
        message: 'This application was marked unsuccessful.',
        color: AppTheme.error,
        icon: Icons.person_remove_outlined,
      );
    case 'cancelled':
      return const _ApplicationStatus(
        label: 'Cancelled',
        message: 'This application is no longer active.',
        color: AppTheme.warning,
        icon: Icons.block_rounded,
      );
    default:
      return const _ApplicationStatus(
        label: 'Pending',
        message: 'This applicant is waiting for your decision.',
        color: AppTheme.warning,
        icon: Icons.schedule_rounded,
      );
  }
}

String _timeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  if (difference.inDays == 1) {
    return 'Yesterday';
  }

  return '${difference.inDays} days ago';
}

String _formatAmount(double amount) {
  return NumberFormat('#,##0').format(amount);
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'A';

  return parts.map((part) => part[0].toUpperCase()).join();
}
