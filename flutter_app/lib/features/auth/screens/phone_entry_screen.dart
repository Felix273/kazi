import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../bloc/auth_bloc.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});
  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  String _formatPhone(String raw) {
    // Strip all non-digits first
    raw = raw.replaceAll(RegExp(r'[^0-9]'), '');
    raw = raw.replaceAll(' ', '').replaceAll('-', '');
    if (raw.startsWith('0')) return '+254${raw.substring(1)}';
    if (raw.startsWith('254')) return '+$raw';
    return raw;
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthRequestOTPEvent(_formatPhone(_controller.text.trim())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state is AuthLoadingState);
        if (state is AuthOTPSentState) context.push('/auth/otp', extra: state.phoneNumber);
        if (state is AuthOTPErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: KaziTheme.error),
          );
        }
      },
      child: Scaffold(
        backgroundColor: KaziTheme.background,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(KaziSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: KaziSpacing.lg),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: KaziTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text('K', style: GoogleFonts.dmSans(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                    ))),
                  ),
                  const SizedBox(height: KaziSpacing.xl),
                  Text('Welcome to\nKazi', style: KaziText.h1),
                  const SizedBox(height: KaziSpacing.sm),
                  Text('Enter your phone number to get started', style: KaziText.body.copyWith(color: KaziTheme.textSecondary)),
                  const SizedBox(height: KaziSpacing.xl),
                  Text('PHONE NUMBER', style: KaziText.label),
                  const SizedBox(height: KaziSpacing.sm),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: GoogleFonts.dmSans(
                      fontSize: 16, fontWeight: FontWeight.w600, color: KaziTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: '+254  ',
                      prefixStyle: GoogleFonts.dmSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: KaziTheme.textPrimary,
                      ),
                      hintText: '7XX XXX XXX',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 9) return 'Enter a valid phone number';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: KaziSpacing.lg),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Code'),
                  ),
                  const Spacer(),
                  Text(
                    'By continuing, you agree to Kazi\'s Terms of Service and Privacy Policy.',
                    style: KaziText.caption.copyWith(color: KaziTheme.textHint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KaziSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
