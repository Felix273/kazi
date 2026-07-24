import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

final walletProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Stream.value(_emptyWallet);
  }

  return FirebaseFirestore.instance
      .collection('wallets')
      .doc(userId)
      .snapshots()
      .map((snapshot) => snapshot.data() ?? _emptyWallet);
});

const _emptyWallet = <String, dynamic>{
  'balanceKES': 0.0,
  'totalEarnedKES': 0.0,
  'totalWithdrawnKES': 0.0,
};

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);

    Future<void> refreshWallet() async {
      ref.invalidate(walletProvider);

      try {
        await ref.read(walletProvider.future);
      } catch (_) {
        // The wallet error state communicates refresh failures.
      }
    }

    return Scaffold(
      bottomNavigationBar: Widgets.bottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/jobseeker/home');
            case 1:
              context.go('/jobseeker/applications');
            case 2:
              context.go('/jobseeker/wallet');
            case 3:
              context.go('/chat');
            case 4:
              context.go('/profile');
          }
        },
      ),
      body: walletAsync.when(
        data: (wallet) {
          final balance = (wallet['balanceKES'] as num?)?.toDouble() ?? 0;
          final earned = (wallet['totalEarnedKES'] as num?)?.toDouble() ?? 0;
          final withdrawn =
              (wallet['totalWithdrawnKES'] as num?)?.toDouble() ?? 0;

          return RefreshIndicator(
            onRefresh: refreshWallet,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  toolbarHeight: 0,
                  expandedHeight: 300,
                  backgroundColor: AppTheme.primaryGreenDark,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _WalletHero(
                      balance: balance,
                      totalEarned: earned,
                      totalWithdrawn: withdrawn,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Widgets.sectionHeader(
                      context: context,
                      title: 'Manage your money',
                      subtitle:
                          'Withdraw earnings or review your payment history.',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _WalletActionCard(
                            icon: Icons.phone_iphone_rounded,
                            title: 'Withdraw',
                            subtitle: 'Send to M-Pesa',
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                showDragHandle: true,
                                builder: (_) {
                                  return _WithdrawSheet(balance: balance);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _WalletActionCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'History',
                            subtitle: 'All transactions',
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                showDragHandle: true,
                                builder: (_) {
                                  return const _TransactionHistorySheet();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Widgets.sectionHeader(
                      context: context,
                      title: 'Recent transactions',
                      subtitle: 'Payments, withdrawals, and wallet activity.',
                      actionLabel: 'View all',
                      onAction: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          showDragHandle: true,
                          builder: (_) {
                            return const _TransactionHistorySheet();
                          },
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: PaymentService.getTransactionHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Column(
                            children: List.generate(
                              3,
                              (index) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == 2 ? 0 : AppSpacing.sm,
                                ),
                                child: Widgets.shimmerLoader(height: 88),
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: const _WalletStateCard(
                            icon: Icons.cloud_off_rounded,
                            title: 'Transactions are unavailable',
                            message:
                                'Check your internet connection and try again.',
                          ),
                        );
                      }

                      final transactions = snapshot.data ?? const [];

                      if (transactions.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: const _WalletStateCard(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'No transactions yet',
                            message:
                                'Complete jobs to start building your Kazi wallet history.',
                          ),
                        );
                      }

                      final recentTransactions = transactions.take(5).toList();

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        itemCount: recentTransactions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, index) {
                          return _TransactionTile(
                            transaction: recentTransactions[index],
                          );
                        },
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          );
        },
        loading: () => const _WalletLoadingView(),
        error: (_, _) => _WalletErrorView(onRetry: refreshWallet),
      ),
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
  });

  final double balance;
  final double totalEarned;
  final double totalWithdrawn;

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
            right: -58,
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
          Positioned(
            left: -40,
            bottom: -54,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'KAZI WALLET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Available balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'KES ${_formatAmount(balance)}',
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Secure earnings balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _WalletMetric(
                          label: 'Total earned',
                          value: totalEarned,
                        ),
                      ),
                      Container(width: 1, height: 44, color: Colors.white24),
                      Expanded(
                        child: _WalletMetric(
                          label: 'Withdrawn',
                          value: totalWithdrawn,
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

class _WalletMetric extends StatelessWidget {
  const _WalletMetric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'KES ${_formatAmount(value)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletActionCard extends StatelessWidget {
  const _WalletActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(icon, size: 21),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionHistorySheet extends StatelessWidget {
  const _TransactionHistorySheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.receipt_long_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction history',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'All wallet activity',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PaymentService.getTransactionHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Widgets.loadingIndicator(
                    message: 'Loading transactions…',
                  );
                }

                if (snapshot.hasError) {
                  return const _WalletStateCard(
                    icon: Icons.cloud_off_rounded,
                    title: 'History is unavailable',
                    message: 'Check your connection and try again.',
                  );
                }

                final transactions = snapshot.data ?? const [];

                if (transactions.isEmpty) {
                  return const _WalletStateCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message: 'Your earnings and withdrawals will appear here.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) {
                    return _TransactionTile(transaction: transactions[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.balance});

  final double balance;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final digits = (userDocument.data()?['phone'] as String? ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (!mounted) return;

    if (digits.startsWith('254') && digits.length == 12) {
      _phoneController.text = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 10) {
      _phoneController.text = digits.substring(1);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();

    final amount = double.parse(_amountController.text.trim());

    setState(() => _submitting = true);

    try {
      final result = await PaymentService.initiateB2CPayout(
        amount: amount,
        phone: '+254${_phoneController.text.trim()}',
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final status = result['status'] as String? ?? 'pending';

      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'completed'
                ? 'Funds have been sent to your M-Pesa account.'
                : 'Your withdrawal request has been received.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The withdrawal could not be completed. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: const Icon(Icons.phone_iphone_rounded, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Withdraw to M-Pesa',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Available balance: KES '
              '${_formatAmount(widget.balance)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Withdrawal amount',
                hintText: '0.00',
                prefixText: 'KES ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }

                if (amount > widget.balance) {
                  return 'Insufficient wallet balance';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              maxLength: 9,
              onFieldSubmitted: (_) {
                if (!_submitting) _withdraw();
              },
              decoration: const InputDecoration(
                labelText: 'M-Pesa number',
                hintText: '7XX XXX XXX',
                prefixText: '+254 ',
                prefixIcon: Icon(Icons.phone_outlined),
                counterText: '',
              ),
              validator: (value) {
                final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                if (!RegExp(r'^[17]\d{8}$').hasMatch(phone)) {
                  return 'Enter a number such as 7XXXXXXXX';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Confirm that the M-Pesa number belongs to you before submitting.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submitting ? null : _withdraw,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: _submitting
                    ? const SizedBox.square(
                        key: ValueKey('loading'),
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text('Confirm withdrawal', key: ValueKey('label')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final type = transaction['type'] as String? ?? 'payment';
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final isCredit =
        type == 'job_payment' || type == 'credit' || type == 'earning';
    final timestamp = transaction['createdAt'] as Timestamp?;

    final date = timestamp == null
        ? 'Pending'
        : DateFormat('d MMM yyyy, HH:mm').format(timestamp.toDate());

    final semanticColor = isCredit ? AppTheme.success : AppTheme.warning;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: semanticColor.withValues(alpha: 0.12),
          foregroundColor: semanticColor,
          child: Icon(
            isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
          ),
        ),
        title: Text(
          transaction['description'] as String? ?? _labelForType(type),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          date,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'} KES '
          '${_formatAmount(amount)}',
          style: TextStyle(color: semanticColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _labelForType(String type) {
    return switch (type) {
      'withdrawal' => 'M-Pesa withdrawal',
      'job_payment' => 'Job payment',
      'escrow' => 'Escrow payment',
      _ => 'Transaction',
    };
  }
}

class _WalletStateCard extends StatelessWidget {
  const _WalletStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon, size: 29),
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
    );
  }
}

class _WalletLoadingView extends StatelessWidget {
  const _WalletLoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          expandedHeight: 300,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: _WalletHero(
              balance: 0,
              totalEarned: 0,
              totalWithdrawn: 0,
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
                child: Widgets.shimmerLoader(height: index == 0 ? 120 : 88),
              ),
              childCount: 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletErrorView extends StatelessWidget {
  const _WalletErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.errorContainer,
                    foregroundColor: scheme.onErrorContainer,
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Wallet is unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Check your connection and try loading your wallet again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatAmount(double amount) {
  return NumberFormat('#,##0.##').format(amount);
}
