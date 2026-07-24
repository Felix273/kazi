import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding tooltips that guide new users through key features
/// Uses visual overlay to highlight UI elements
class OnboardingTooltips extends ConsumerStatefulWidget {
  final Widget child;
  final String role; // 'jobseeker' or 'employer'

  const OnboardingTooltips({
    super.key,
    required this.child,
    required this.role,
  });

  @override
  ConsumerState<OnboardingTooltips> createState() => _OnboardingTooltipsState();
}

class _OnboardingTooltipsState extends ConsumerState<OnboardingTooltips>
    with WidgetsBindingObserver {
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _firstJobKey = GlobalKey();
  final GlobalKey _walletKey = GlobalKey();
  final GlobalKey _postJobKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _jobCardKey = GlobalKey();

  int _currentStep = 0;
  OverlayEntry? _overlayEntry;
  bool _showing = false;
  bool _completed = false;

  static const String _prefKey = 'onboarding_tooltips_completed';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkIfCompleted();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeOverlay();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_showing) {
      _removeOverlay();
      _showOverlay();
    }
  }

  Future<void> _checkIfCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completed = prefs.getBool('${_prefKey}_${widget.role}') ?? false;
    });
  }

  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefKey}_${widget.role}', true);
    setState(() => _completed = true);
  }

  void _show() {
    if (_completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showOverlay();
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        currentStep: _currentStep,
        role: widget.role,
        locationKey: _locationKey,
        filterKey: _filterKey,
        firstJobKey: _firstJobKey,
        walletKey: _walletKey,
        postJobKey: _postJobKey,
        statsKey: _statsKey,
        jobCardKey: _jobCardKey,
        onNext: _nextStep,
        onSkip: _skipAll,
        onDone: _complete,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showing = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showing = false);
  }

  void _nextStep() {
    final maxSteps = widget.role == 'jobseeker' ? 4 : 3;
    if (_currentStep < maxSteps - 1) {
      setState(() => _currentStep++);
      _showOverlay();
    }
  }

  void _skipAll() {
    _removeOverlay();
    _markCompleted();
  }

  void _complete() {
    _currentStep = widget.role == 'jobseeker' ? 3 : 2;
    _removeOverlay();
    _markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_completed)
          Positioned.fill(
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_showing && !_completed) _show();
                });
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }
}

class _TooltipOverlay extends StatelessWidget {
  final int currentStep;
  final String role;
  final GlobalKey locationKey;
  final GlobalKey filterKey;
  final GlobalKey firstJobKey;
  final GlobalKey walletKey;
  final GlobalKey postJobKey;
  final GlobalKey statsKey;
  final GlobalKey jobCardKey;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onDone;

  const _TooltipOverlay({
    required this.currentStep,
    required this.role,
    required this.locationKey,
    required this.filterKey,
    required this.firstJobKey,
    required this.walletKey,
    required this.postJobKey,
    required this.statsKey,
    required this.jobCardKey,
    required this.onNext,
    required this.onSkip,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      child: Stack(
        children: [
          Positioned.fill(child: _buildStepContent(context)),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            right: 12,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    if (role == 'jobseeker') {
      return _buildJobSeekerSteps(context);
    }
    return _buildEmployerSteps(context);
  }

  Widget _buildJobSeekerSteps(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _highlightWidget(
          context,
          locationKey,
          title: 'Set your location',
          subtitle:
              'Use your location to discover relevant opportunities nearby.',
          arrowDirection: ArrowDirection.down,
        );
      case 1:
        return _highlightWidget(
          context,
          filterKey,
          title: 'Refine your search',
          subtitle:
              'Filter opportunities by category, distance, schedule, and pay.',
          arrowDirection: ArrowDirection.down,
        );
      case 2:
        return _highlightWidget(
          context,
          firstJobKey,
          title: 'Review opportunities',
          subtitle:
              'Open a job card to review its requirements, pay, and location.',
          arrowDirection: ArrowDirection.down,
        );
      case 3:
        return _highlightWidget(
          context,
          walletKey,
          title: 'Manage your earnings',
          subtitle: 'Track your balance, payments, and withdrawals securely.',
          arrowDirection: ArrowDirection.up,
        );
      default:
        return _buildDoneState(context);
    }
  }

  Widget _buildEmployerSteps(BuildContext context) {
    switch (currentStep) {
      case 0:
        return _highlightWidget(
          context,
          postJobKey,
          title: 'Post a job',
          subtitle:
              'Provide clear work details, budget, schedule, and location.',
          arrowDirection: ArrowDirection.down,
        );
      case 1:
        return _highlightWidget(
          context,
          statsKey,
          title: 'Track hiring activity',
          subtitle:
              'Review applications, active listings, and hiring performance.',
          arrowDirection: ArrowDirection.down,
        );
      case 2:
        return _highlightWidget(
          context,
          jobCardKey,
          title: 'Manage your listings',
          subtitle:
              'Open a listing to review applicants and update its status.',
          arrowDirection: ArrowDirection.down,
        );
      default:
        return _buildDoneState(context);
    }
  }

  Widget _buildDoneState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: colors.primary, size: 64),
            const SizedBox(height: 18),
            Text(
              'You are ready to get started',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'You now know the essentials. Start using Kazi with confidence.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onDone,
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightWidget(
    BuildContext context,
    GlobalKey targetKey, {
    required String title,
    required String subtitle,
    required ArrowDirection arrowDirection,
  }) {
    final targetContext = targetKey.currentContext;
    final renderBox = targetContext?.findRenderObject() as RenderBox?;

    if (targetContext == null || renderBox == null || !renderBox.hasSize) {
      return const SizedBox.shrink();
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.sizeOf(context);
    final colors = Theme.of(context).colorScheme;

    final tooltipTop = arrowDirection == ArrowDirection.down
        ? math.max(
            24.0,
            math.min(position.dy + size.height + 20, screenSize.height - 250),
          )
        : null;

    final tooltipBottom = arrowDirection == ArrowDirection.up
        ? math.max(screenSize.height - position.dy + 16, 24.0)
        : null;

    return Stack(
      children: [
        Positioned(
          left: math.max(position.dx - 8, 8),
          top: math.max(position.dy - 8, 8),
          child: IgnorePointer(
            child: Container(
              width: math.min(size.width + 16, screenSize.width - 16),
              height: size.height + 16,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: tooltipTop,
          bottom: tooltipBottom,
          child: Material(
            color: colors.surface,
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: onSkip, child: const Text('Skip')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onNext,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum ArrowDirection { up, down, left, right }
