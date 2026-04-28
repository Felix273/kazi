import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../auth/bloc/auth_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticatedState ? authState.user : null;

    return Scaffold(
      backgroundColor: KaziTheme.background,
      body: ListView(
        children: [
          Container(
            color: KaziTheme.surface,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: KaziTheme.primary,
                      child: Text(
                        user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : '?',
                        style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: KaziTheme.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? '', style: KaziText.h2),
                const SizedBox(height: 4),
                Text(user?.phoneNumber ?? '', style: KaziText.caption),
                const SizedBox(height: 12),
                if (user?.isVerified == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: KaziTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: KaziTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: KaziTheme.primary),
                        const SizedBox(width: 4),
                        Text('Verified', style: GoogleFonts.dmSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: KaziTheme.primary,
                        )),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => context.push('/profile/kyc'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: KaziTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KaziTheme.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: KaziTheme.accent),
                          const SizedBox(width: 4),
                          Text('Get Verified', style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: KaziTheme.accent,
                          )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: KaziSpacing.sm),

          // Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: KaziSpacing.md),
            decoration: BoxDecoration(
              color: KaziTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KaziTheme.border),
            ),
            child: Row(
              children: [
                _StatItem(label: 'Rating', value: '${user?.averageRating.toStringAsFixed(1)}★'),
                Container(width: 1, height: 40, color: KaziTheme.border),
                _StatItem(label: 'Reviews', value: '${user?.totalReviews}'),
                Container(width: 1, height: 40, color: KaziTheme.border),
                _StatItem(label: 'Jobs Done', value: '${user?.totalJobsCompleted}'),
              ],
            ),
          ),

          const SizedBox(height: KaziSpacing.sm),

          // Menu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: KaziSpacing.md),
            decoration: BoxDecoration(
              color: KaziTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KaziTheme.border),
            ),
            child: Column(
              children: [
                _MenuItem(icon: Icons.work_outline_rounded, label: 'My Jobs', onTap: () {}),
                _MenuItem(icon: Icons.payments_outlined, label: 'Earnings & Payments', onTap: () {}),
                _MenuItem(icon: Icons.shield_outlined, label: 'Verify Identity', onTap: () => context.push('/profile/kyc')),
                _MenuItem(icon: Icons.star_outline_rounded, label: 'My Reviews', onTap: () {}),
                _MenuItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  isDestructive: true,
                  onTap: () => context.read<AuthBloc>().add(AuthLogoutEvent()),
                  showArrow: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: KaziSpacing.xl),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: KaziText.h3),
          const SizedBox(height: 2),
          Text(label, style: KaziText.caption),
        ],
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showArrow;

  const _MenuItem({
    required this.icon, required this.label, required this.onTap,
    this.isDestructive = false, this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDestructive ? KaziTheme.error.withOpacity(0.08) : KaziTheme.surfaceWarm,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18,
              color: isDestructive ? KaziTheme.error : KaziTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: KaziText.bodyMedium.copyWith(
            color: isDestructive ? KaziTheme.error : KaziTheme.textPrimary,
          ))),
          if (showArrow)
            const Icon(Icons.chevron_right_rounded, color: KaziTheme.textHint, size: 20),
        ],
      ),
    ),
  );
}
