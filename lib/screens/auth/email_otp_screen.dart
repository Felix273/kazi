import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/otp_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_shell.dart';

class EmailOtpScreen extends StatefulWidget {
  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.role,
    required this.purpose,
    required this.onVerified,
    this.displayName,
  });

  final String email;
  final String role;
  final String purpose;
  final String? displayName;
  final Future<UserModelResult> Function() onVerified;

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class UserModelResult {
  const UserModelResult({required this.profile});
  final dynamic profile;
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendSeconds = 60;
  Timer? _timer;

  bool get _isEmployer => widget.role == 'employer';

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendCode();
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
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

  Future<void> _sendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      await OtpService.sendEmailOtp(
        email: widget.email,
        purpose: widget.purpose,
        name: widget.displayName,
      );
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _resendSeconds = 60;
      });
      _startResendTimer();
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
    } on OtpException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isResending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not send the verification code. Try again.';
        _isResending = false;
      });
    }
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
      final verified = await OtpService.verifyEmailOtp(
        email: widget.email,
        code: otp,
        purpose: widget.purpose,
      );
      if (!verified) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'The verification code is incorrect.';
          _isLoading = false;
        });
        return;
      }
      await widget.onVerified();
    } on OtpException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We could not verify the code. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      title: 'Check your email',
      subtitle:
          'Enter the secure six-digit code we sent to ${widget.email}.',
      roleLabel: _isEmployer ? 'Employer verification' : 'Account verification',
      icon: Icons.mark_email_read_outlined,
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
                child: Icon(Icons.email_rounded, color: scheme.primary),
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
                      widget.email,
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
                  _resendSeconds == 0
                      ? Icons.refresh_rounded
                      : Icons.timer_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _resendSeconds == 0
                        ? 'Did not receive the code?'
                        : 'You can request another code in '
                              '$_resendSeconds seconds.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
                if (_resendSeconds == 0)
                  TextButton(
                    onPressed: _isResending ? null : _sendCode,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend'),
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
