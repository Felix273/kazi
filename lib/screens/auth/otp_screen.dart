import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.role,
  });

  final String verificationId;
  final String phoneNumber;
  final String role;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  String? _errorMessage;
  int _resendSeconds = 60;
  Timer? _timer;
  late String _verificationId;

  bool get _isEmployer => widget.role == AppConstants.roleEmployer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_resendSeconds <= 1) {
        timer.cancel();

        setState(() {
          _resendSeconds = 0;
          _canResend = true;
        });

        return;
      }

      setState(() => _resendSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
      return;
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyCode() async {
    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Enter the complete 6-digit verification code.';
      });
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (FirebaseAuth.instance.currentUser != null) {
        await _onSignInSuccess();
      }
    } on FirebaseAuthException catch (error) {
      _logPhoneAuthError('code verification', error);

      if (!mounted) return;

      setState(() {
        _errorMessage = _phoneAuthErrorMessage(error);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unexpected OTP verification error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage =
            'We could not verify this code. Try again or request a new code.';
        _isLoading = false;
      });
    }
  }

  void _logPhoneAuthError(String stage, FirebaseAuthException error) {
    debugPrint(
      'Phone authentication $stage failed: '
      '${error.code}: ${error.message}',
    );
  }

  String _phoneAuthErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-verification-code' =>
        'That verification code is incorrect. Try again.',
      'invalid-verification-id' || 'missing-verification-id' =>
        'This verification session is invalid. Request a new code.',
      'missing-verification-code' =>
        'Enter the complete 6-digit verification code.',
      'session-expired' =>
        'This verification code has expired. Request a new one.',
      'network-request-failed' =>
        'A network error occurred. Check your connection and try again.',
      'too-many-requests' =>
        'Too many verification attempts. Wait and try again.',
      'quota-exceeded' =>
        'The SMS verification limit has been reached. Try again later.',
      'operation-not-allowed' => 'Phone sign-in is currently unavailable.',
      'app-not-authorized' =>
        'This app is not authorized for phone authentication.',
      'invalid-app-credential' || 'captcha-check-failed' =>
        'App security verification failed. Request a new code.',
      _ => error.message ?? 'Phone verification failed. Please try again.',
    };
  }

  Future<void> _onSignInSuccess() async {
    final profile = await AuthService.getUserProfileOnce();

    if (!mounted) return;

    if (profile == null) {
      context.go('/auth/complete-profile', extra: {'role': widget.role});
      return;
    }

    await SessionService.save(profile.role);

    if (!mounted) return;

    context.go(SessionService.homeForRole(profile.role));
  }

  Future<void> _resendCode() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resendSeconds = 60;
      _canResend = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _onSignInSuccess();
        },
        verificationFailed: (error) {
          _logPhoneAuthError('code resend', error);

          if (!mounted) return;

          setState(() {
            _errorMessage = _phoneAuthErrorMessage(error);
            _isLoading = false;
          });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });

          for (final controller in _otpControllers) {
            controller.clear();
          }

          _focusNodes.first.requestFocus();
          _startResendTimer();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new verification code has been sent.'),
            ),
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (error) {
      _logPhoneAuthError('code resend', error);

      if (!mounted) return;

      setState(() {
        _errorMessage = _phoneAuthErrorMessage(error);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unexpected phone-code resend error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'We could not send a new verification code. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      title: 'Check your messages',
      subtitle:
          'Enter the secure six-digit code sent to ${widget.phoneNumber}.',
      roleLabel: _isEmployer ? 'Employer verification' : 'Account verification',
      icon: Icons.sms_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.phoneNumber,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == 5 ? 0 : AppSpacing.xs,
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    autofillHints: index == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onChanged: (value) => _onOtpChanged(value, index),
                    onSubmitted: (_) {
                      if (index == 5 && !_isLoading) {
                        _verifyCode();
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthErrorBanner(message: _errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _isLoading ? null : _verifyCode,
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Verify and continue', key: ValueKey('label')),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  _canResend ? Icons.refresh_rounded : Icons.timer_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _canResend
                        ? 'Did not receive the code?'
                        : 'You can request another code in '
                              '$_resendSeconds seconds.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
                if (_canResend)
                  TextButton(
                    onPressed: _resendCode,
                    child: const Text('Resend'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Never share this code with anyone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
