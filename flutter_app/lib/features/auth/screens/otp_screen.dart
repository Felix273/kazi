import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

import '../../../core/theme.dart';
import '../bloc/auth_bloc.dart';
import '../../../shared/widgets/kazi_button.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;
  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _verify(String code) {
    if (code.length == 6) {
      context.read<AuthBloc>().add(
        AuthVerifyOTPEvent(widget.phoneNumber, code),
      );
    }
  }

  void _resend() {
    context.read<AuthBloc>().add(AuthRequestOTPEvent(widget.phoneNumber));
    _pinController.clear();
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
        fontFamily: 'Sora',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: KaziTheme.textPrimary,
      ),
      decoration: BoxDecoration(
        color: KaziTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KaziTheme.border),
      ),
    );

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoadingState) {
          setState(() => _isLoading = true);
          return;
        }
        setState(() => _isLoading = false);

        if (state is AuthNeedsRegistrationState) {
          context.go('/auth/register');
          return;
        }
        if (state is AuthAuthenticatedState) {
          context.go('/home');
          return;
        }
        if (state is AuthOTPErrorState) {
          _pinController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: KaziTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: KaziTheme.background,
          appBar: AppBar(
            backgroundColor: KaziTheme.background,
            elevation: 0,
            leading: const BackButton(color: KaziTheme.textPrimary),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(KaziSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: KaziSpacing.lg),
                  Text('Enter the code', style: KaziText.h1),
                  const SizedBox(height: KaziSpacing.sm),
                  Text(
                    'We sent a 6-digit code to\n${widget.phoneNumber}',
                    style: KaziText.body,
                  ),
                  const SizedBox(height: KaziSpacing.xl),
                  Center(
                    child: Pinput(
                      controller: _pinController,
                      length: 6,
                      autofocus: true,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyDecorationWith(
                        border: Border.all(color: KaziTheme.primary, width: 1.5),
                        color: Colors.white,
                      ),
                      submittedPinTheme: defaultPinTheme.copyDecorationWith(
                        border: Border.all(color: KaziTheme.primary),
                        color: KaziTheme.primary.withOpacity(0.08),
                      ),
                      onCompleted: _verify,
                    ),
                  ),
                  const SizedBox(height: KaziSpacing.xl),
                  KaziButton(
                    label: 'Verify',
                    onPressed: () => _verify(_pinController.text),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: KaziSpacing.lg),
                  Center(
                    child: _resendCountdown > 0
                        ? Text(
                            'Resend code in ${_resendCountdown}s',
                            style: KaziText.body.copyWith(
                              color: KaziTheme.textHint,
                            ),
                          )
                        : TextButton(
                            onPressed: _resend,
                            child: const Text(
                              'Resend code',
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontWeight: FontWeight.w600,
                                color: KaziTheme.primary,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
