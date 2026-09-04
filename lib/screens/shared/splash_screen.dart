import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.78, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final preferences = await SharedPreferences.getInstance();
    final isFirstLaunch =
        preferences.getBool(AppConstants.prefFirstLaunch) ?? true;

    if (isFirstLaunch) {
      await preferences.setBool(AppConstants.prefFirstLaunch, false);
      if (mounted) context.go('/onboarding');
      return;
    }

    await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) return;

    if (!AuthService.isLoggedIn) {
      await SessionService.clear();
      if (mounted) context.go('/role');
      return;
    }

    final profile = await AuthService.getUserProfileOnce();
    if (!mounted) return;

    if (profile == null) {
      final role = await SessionService.role ?? AppConstants.roleJobseeker;

      if (mounted) {
        context.go('/auth/complete-profile', extra: {'role': role});
      }
      return;
    }

    await SessionService.save(profile.role);

    if (mounted) {
      context.go(SessionService.homeForRole(profile.role));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF1B5E20),
              Color(0xFF155018),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: -120,
              right: -80,
              child: _GlowOrb(
                size: 300,
                color: AppTheme.accentGold,
                opacity: 0.08,
              ),
            ),
            const Positioned(
              bottom: -150,
              left: -110,
              child: _GlowOrb(
                size: 360,
                color: Color(0xFF45C998),
                opacity: 0.09,
              ),
            ),
            Positioned(
              top: 120,
              left: -35,
              child: Transform.rotate(
                angle: -0.25,
                child: Container(
                  width: 150,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.025),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 238,
                          height: 238,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(54),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 70,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 42,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.asset(
                              'assets/images/kazi_brand.png',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, _, _) => const ColoredBox(
                                color: Color(0xFF1B5E20),
                                child: Icon(
                                  Icons.work_rounded,
                                  size: 104,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              AppConstants.appName,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Local work. Trusted talent.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 116,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                color: AppTheme.accentGold,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'WORK STARTS HERE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.46),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 100,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}
