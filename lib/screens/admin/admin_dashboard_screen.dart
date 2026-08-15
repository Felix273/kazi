import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/dispute_service.dart';
import '../../utils/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.gavel_outlined), text: 'Disputes'),
            Tab(
              icon: Icon(Icons.verified_user_outlined),
              text: 'Verifications',
            ),
            Tab(
              icon: Icon(Icons.campaign_outlined),
              text: 'Broadcast',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AdminOverviewTab(),
          _AdminDisputesTab(),
          _AdminVerificationsTab(),
          _AdminBroadcastTab(),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatefulWidget {
  const _AdminOverviewTab();

  @override
  State<_AdminOverviewTab> createState() => _AdminOverviewTabState();
}

class _AdminOverviewTabState extends State<_AdminOverviewTab> {
  Future<Map<String, dynamic>>? _metricsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
  }

  void _refreshMetrics() {
    setState(() {
      _metricsFuture = AdminService.getAdminMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        _refreshMetrics();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform KPI Metrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refreshMetrics,
                tooltip: 'Refresh metrics',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<Map<String, dynamic>>(
            future: _metricsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text('Failed to load metrics: ${snapshot.error}'),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    title: 'Total Users',
                    value: '${data['totalUsers'] ?? 0}',
                    icon: Icons.people_outline_rounded,
                    color: AppTheme.blue,
                  ),
                  _MetricCard(
                    title: 'Open Jobs',
                    value: '${data['openJobs'] ?? 0}',
                    icon: Icons.work_outline_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  _MetricCard(
                    title: 'Open Disputes',
                    value: '${data['openDisputes'] ?? 0}',
                    icon: Icons.report_problem_outlined,
                    color: AppTheme.error,
                  ),
                  _MetricCard(
                    title: 'Pending Verifications',
                    value: '${data['pendingVerifications'] ?? 0}',
                    icon: Icons.badge_outlined,
                    color: AppTheme.warning,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'System Admin Alerts',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: AdminService.getAdminAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No system alerts at this time.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.errorContainer,
                        foregroundColor: scheme.onErrorContainer,
                        child: const Icon(Icons.notifications_active_outlined),
                      ),
                      title: Text(alert['message'] ?? 'Alert'),
                      subtitle: Text('Type: ${alert['type'] ?? 'General'}'),
                      trailing: Text(
                        alert['status'] ?? 'open',
                        style: TextStyle(
                          color: alert['status'] == 'open'
                              ? AppTheme.error
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDisputesTab extends StatelessWidget {
  const _AdminDisputesTab();

  void _showResolveModal(BuildContext context, String disputeId) {
    final resolutionController = TextEditingController();
    bool releasePayment = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom +
                    AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolve Dispute',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: resolutionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Summary',
                      hintText: 'Describe outcome or actions taken...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: releasePayment,
                    title: const Text('Release Escrow Payment to Reporter'),
                    onChanged: (val) {
                      setState(() {
                        releasePayment = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: () async {
                      if (resolutionController.text.trim().isEmpty) return;
                      try {
                        await DisputeService.resolveDispute(
                          disputeId: disputeId,
                          resolution: resolutionController.text.trim(),
                          releasePayment: releasePayment,
                        );
                        if (context.mounted) {
                          Navigator.pop(bottomSheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dispute resolved successfully.'),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    child: const Text('Confirm Resolution'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.getAllDisputes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final disputes = snapshot.data ?? [];
        if (disputes.isEmpty) {
          return const Center(child: Text('No disputes reported.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final dispute = disputes[index];
            final isResolved = dispute['status'] == 'resolved';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dispute['reasonLabel'] ?? 'Dispute',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(dispute['status'] ?? 'open'),
                          backgroundColor: isResolved
                              ? scheme.primaryContainer
                              : scheme.errorContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dispute['description'] ?? 'No description provided.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Job ID: ${dispute['jobId']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (isResolved && dispute['resolution'] != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Resolution: ${dispute['resolution']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (!isResolved) ...[
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Resolve'),
                          onPressed: () => _showResolveModal(
                            context,
                            dispute['id'] as String,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminVerificationsTab extends StatelessWidget {
  const _AdminVerificationsTab();

  void _reviewVerification(
    BuildContext context,
    String userId,
    bool approve,
  ) async {
    String? rejectionReason;
    if (!approve) {
      final controller = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reject Verification'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'e.g. Unclear ID document photo',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      rejectionReason = controller.text.trim();
    }

    try {
      await AdminService.reviewUserVerification(
        userId: userId,
        approved: approve,
        rejectionReason: rejectionReason,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Verification approved!' : 'Verification rejected.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.getPendingVerifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text('No pending identity verifications.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final idPhotoUrl = item['idPhotoUrl'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ID: ${item['userId']}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('ID Number: ${item['idNumber'] ?? 'N/A'}'),
                    if (idPhotoUrl != null && idPhotoUrl.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.network(
                          idPhotoUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _reviewVerification(
                            context,
                            item['userId'] as String,
                            false,
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () => _reviewVerification(
                            context,
                            item['userId'] as String,
                            true,
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminBroadcastTab extends StatefulWidget {
  const _AdminBroadcastTab();

  @override
  State<_AdminBroadcastTab> createState() => _AdminBroadcastTabState();
}

class _AdminBroadcastTabState extends State<_AdminBroadcastTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and body.')),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final res = await AdminService.sendBroadcastNotification(
        title: title,
        body: body,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Broadcast sent! Success: ${res['successCount'] ?? 0}, Failures: ${res['failureCount'] ?? 0}',
            ),
          ),
        );
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Send Platform Announcement',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Broadcast push notifications to all active platform users.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Notification Title',
            hintText: 'e.g. New Feature Announcement',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notification Message Body',
            hintText: 'Type your message here...',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: _sending ? null : _sendBroadcast,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_sending ? 'Sending...' : 'Send Broadcast'),
        ),
      ],
    );
  }
}
