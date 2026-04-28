import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../bloc/auth_bloc.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String _userType = 'worker';
  bool _isLoading = false;

  @override
  void dispose() { _firstCtrl.dispose(); _lastCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthCompleteRegistrationEvent({
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
        'user_type': _userType,
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = state is AuthLoadingState);
        if (state is AuthAuthenticatedState) context.go('/home');
        if (state is AuthErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: KaziTheme.error),
          );
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: KaziTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KaziSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: KaziSpacing.xl),
                  Text('Set up your\nprofile', style: KaziText.h1),
                  const SizedBox(height: KaziSpacing.sm),
                  Text('Just a few details to get started', style: KaziText.body.copyWith(color: KaziTheme.textSecondary)),
                  const SizedBox(height: KaziSpacing.xl),
                  TextFormField(
                    controller: _firstCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'First name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: KaziSpacing.md),
                  TextFormField(
                    controller: _lastCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Last name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: KaziSpacing.xl),
                  Text('I want to...', style: KaziText.h3),
                  const SizedBox(height: KaziSpacing.md),
                  _RoleCard(
                    title: 'Find work',
                    subtitle: 'Looking for jobs and tasks',
                    icon: '🔨',
                    isSelected: _userType == 'worker',
                    onTap: () => setState(() => _userType = 'worker'),
                  ),
                  const SizedBox(height: KaziSpacing.sm),
                  _RoleCard(
                    title: 'Hire workers',
                    subtitle: 'Need jobs and tasks done',
                    icon: '🏢',
                    isSelected: _userType == 'employer',
                    onTap: () => setState(() => _userType = 'employer'),
                  ),
                  const SizedBox(height: KaziSpacing.sm),
                  _RoleCard(
                    title: 'Both',
                    subtitle: 'Hire and find work',
                    icon: '⇄',
                    isSelected: _userType == 'both',
                    onTap: () => setState(() => _userType = 'both'),
                  ),
                  const SizedBox(height: KaziSpacing.xl),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: KaziSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title, subtitle, icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleCard({required this.title, required this.subtitle, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(KaziSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? KaziTheme.primary : KaziTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? KaziTheme.primary : KaziTheme.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : KaziTheme.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: KaziSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : KaziTheme.textPrimary,
                  )),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.dmSans(
                    fontSize: 12, color: isSelected ? Colors.white.withOpacity(0.7) : KaziTheme.textSecondary,
                  )),
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : KaziTheme.border, width: 2,
                ),
              ),
              child: isSelected
                  ? Center(child: Container(width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: KaziTheme.primary)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
