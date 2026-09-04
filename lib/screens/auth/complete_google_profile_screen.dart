import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_shell.dart';

class CompleteGoogleProfileScreen extends ConsumerStatefulWidget {
  const CompleteGoogleProfileScreen({
    super.key,
    required this.role,
    required this.initialName,
    required this.email,
    this.photoUrl,
  });

  final String role;
  final String initialName;
  final String email;
  final String? photoUrl;

  @override
  ConsumerState<CompleteGoogleProfileScreen> createState() =>
      _CompleteGoogleProfileScreenState();
}

class _CompleteGoogleProfileScreenState
    extends ConsumerState<CompleteGoogleProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _neighborhood;
  String? _error;
  bool _saving = false;

  bool get _isEmployer => widget.role == AppConstants.roleEmployer;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final profile = await AuthService.completeGoogleProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: widget.role,
        neighborhood: _neighborhood,
        photoUrl: widget.photoUrl,
      );

      if (!mounted) return;
      context.go(SessionService.homeForRole(profile.role));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AuthShell(
      title: 'One last step',
      subtitle: _isEmployer
          ? 'Complete your profile before posting and managing jobs.'
          : 'Complete your profile before discovering nearby opportunities.',
      roleLabel: _isEmployer ? 'Employer profile' : 'Job seeker profile',
      icon: _isEmployer
          ? Icons.business_center_rounded
          : Icons.person_search_rounded,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete your profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'These details help us personalise your Kazi experience.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Your first and last name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Enter your full name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+254 7XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your phone number.';
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9) {
                    return 'Enter a valid phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _neighborhood,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Neighborhood',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: AppConstants.nairobiNeighborhoods
                    .map(
                      (neighborhood) => DropdownMenuItem<String>(
                        value: neighborhood,
                        child: Text(
                          neighborhood,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _neighborhood = value;
                    _error = null;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Select your neighborhood.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_searching_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _isEmployer
                            ? 'Your location helps Kazi connect your jobs with suitable nearby applicants.'
                            : 'Your location helps Kazi surface relevant opportunities near you.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                AuthErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.shrink()
                    : const Icon(Icons.arrow_forward_rounded),
                iconAlignment: IconAlignment.end,
                label: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: _saving
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Complete profile', key: ValueKey('label')),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You can update these details later from your profile.',
                textAlign: TextAlign.center,
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
