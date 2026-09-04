import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_shell.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key, required this.role});

  final String role;

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;

  bool get _isEmployer => widget.role == AppConstants.roleEmployer;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.length != AppConstants.phoneLength) {
      setState(() {
        _errorMessage =
            'Enter a valid ${AppConstants.phoneLength}-digit mobile number.';
      });
      return;
    }

    if (!AppConstants.phoneRegex.hasMatch(phoneNumber)) {
      setState(() {
        _errorMessage = 'The phone number can only contain digits.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${AppConstants.phonePrefix}$phoneNumber',
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _finishPhoneSignIn();
        },
        verificationFailed: (error) {
          if (!mounted) return;

          setState(() {
            _errorMessage = _getErrorMessage(error);
            _isLoading = false;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });

          context.push(
            '/auth/otp',
            extra: {
              'verificationId': verificationId,
              'phoneNumber': '${AppConstants.phonePrefix}$phoneNumber',
              'role': widget.role,
            },
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Something went wrong. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid mobile number.';
      case 'too-many-requests':
        return 'Too many verification attempts. Try again later.';
      case 'network-request-failed':
        return 'A network error occurred. Check your connection.';
      case 'quota-exceeded':
        return 'The verification limit has been reached. Try again later.';
      case 'session-expired':
        return 'The verification session expired. Please try again.';
      default:
        return error.message ?? 'Phone verification failed. Please try again.';
    }
  }

  Future<void> _finishPhoneSignIn() async {
    var profile = await AuthService.getUserProfileOnce();
    if (!mounted) return;

    if (profile == null) {
      context.go('/auth/complete-profile', extra: {'role': widget.role});
      return;
    }

    final currentProfile = profile;
    if (currentProfile.role != widget.role) {
      try {
        await AuthService.updateUserRole(widget.role);
        profile = currentProfile.copyWith(role: widget.role);
      } catch (_) {}
    }

    final finalProfile = profile;
    if (finalProfile == null) return;
    await SessionService.save(finalProfile.role);
    if (!mounted) return;

    context.go(SessionService.homeForRole(finalProfile.role));
  }

  void _openOtpScreen() {
    final verificationId = _verificationId;
    if (verificationId == null) return;

    context.push(
      '/auth/otp',
      extra: {
        'verificationId': verificationId,
        'phoneNumber':
            '${AppConstants.phonePrefix}${_phoneController.text.trim()}',
        'role': widget.role,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      title: 'Continue by phone',
      subtitle: _isEmployer
          ? 'Verify your number to access jobs and receive secure M-Pesa prompts.'
          : 'Verify your mobile number to access your Kazi account.',
      roleLabel: _isEmployer ? 'Employer access' : 'Job seeker access',
      icon: Icons.phone_iphone_rounded,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mobile verification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We will send a six-digit SMS code.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              maxLength: AppConstants.phoneLength,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.phoneLength),
              ],
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onSubmitted: (_) {
                if (!_isLoading) _sendCode();
              },
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '7XX XXX XXX',
                prefixIcon: Icon(Icons.phone_iphone_rounded),
                prefixText: '+254 ',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: scheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your number is used only for account access and essential Kazi services.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              AuthErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _isLoading ? null : _sendCode,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.sms_outlined),
              label: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: _isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text(
                        'Send verification code',
                        key: ValueKey('label'),
                      ),
              ),
            ),
            if (_verificationId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _openOtpScreen,
                child: const Text('Enter the code again'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 17,
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Standard SMS delivery times may apply.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
