import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_strings.dart';
import '../../utils/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loadingAccount = true;
  String _phoneNumber = '';
  double _searchRadius = AppConstants.defaultSearchRadius;

  @override
  void initState() {
    super.initState();
    _loadAccountSummary();
  }

  Future<void> _loadAccountSummary() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final preferences = await SharedPreferences.getInstance();

      String phone = user?.phoneNumber ?? '';

      if (user != null) {
        final document = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        phone = document.data()?['phone'] as String? ?? phone;
      }

      if (!mounted) return;

      setState(() {
        _phoneNumber = phone;
        _searchRadius =
            preferences.getDouble(AppConstants.prefSearchRadius) ??
            AppConstants.defaultSearchRadius;
        _loadingAccount = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _loadingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAccountSummary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 310,
              backgroundColor: AppTheme.primaryGreenDark,
              foregroundColor: Colors.white,
              title: const Text('Settings'),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _SettingsHero(
                  phoneNumber: _phoneNumber,
                  loading: _loadingAccount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _SettingsIntroduction(
                  themeMode: themeMode,
                  searchRadius: _searchRadius,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _SettingsSectionCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Account',
                  description: 'Manage your identity and contact information.',
                  children: [
                    _SettingsActionTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Edit profile',
                      subtitle: 'Photo, skills, bio, and availability',
                      onTap: () {
                        context.go('/profile');
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.phone_android_rounded,
                      title: 'Phone number',
                      subtitle: _phoneNumber.isEmpty
                          ? 'Add a verified phone number'
                          : _maskPhone(_phoneNumber),
                      onTap: () {
                        _showChangePhoneDialog(context);
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Identity verification',
                      subtitle: 'Review your verification status',
                      onTap: () {
                        context.go('/profile');
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _SettingsSectionCard(
                  icon: Icons.tune_rounded,
                  title: 'Preferences',
                  description: 'Personalise how Kazi looks and works.',
                  children: [
                    _SettingsActionTile(
                      icon: _themeModeIcon(themeMode),
                      title: 'Appearance',
                      subtitle: _themeModeLabel(themeMode),
                      onTap: () {
                        _showThemeSelector(context);
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Job, message, and payment alerts',
                      onTap: () {
                        context.go('/settings/notifications');
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.location_searching_rounded,
                      title: 'Job search radius',
                      subtitle: '${_searchRadius.toStringAsFixed(0)} km',
                      onTap: () {
                        _showSearchRadiusDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _SettingsSectionCard(
                  icon: Icons.support_agent_rounded,
                  title: 'Help and support',
                  description:
                      'Get answers, contact support, or review policies.',
                  children: [
                    _SettingsActionTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Frequently asked questions',
                      subtitle: 'Common questions about using Kazi',
                      onTap: () {
                        _showFaq(context);
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Contact support',
                      subtitle: 'Continue the conversation on WhatsApp',
                      onTap: () {
                        _launchWhatsApp(context);
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.star_outline_rounded,
                      title: 'Rate Kazi',
                      subtitle: 'Share feedback on Google Play',
                      onTap: () {
                        _launchPlayStore(context);
                      },
                    ),
                    _SettingsActionTile(
                      icon: Icons.policy_outlined,
                      title: 'Terms and privacy',
                      subtitle: 'Review platform policies',
                      onTap: () {
                        _showTerms(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: _AccountSecurityCard(
                  onLogout: () {
                    _showLogoutDialog(context);
                  },
                  onDelete: () {
                    _showDeleteAccountDialog(context);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SettingsFooter()),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePhoneDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final phone = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;

        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.phone_android_rounded, size: 28),
          ),
          title: const Text('Change phone number'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A verification code will be sent to the new number.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 9,
                  decoration: const InputDecoration(
                    labelText: 'New phone number',
                    hintText: '7XX XXX XXX',
                    prefixText: '+254 ',
                    counterText: '',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                    if (!RegExp(r'^[17]\d{8}$').hasMatch(digits)) {
                      return 'Enter a valid Kenyan mobile number';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  controller.text.replaceAll(RegExp(r'\D'), ''),
                );
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send code'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (phone == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Sending verification code…')),
      );

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+254$phone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await _applyPhoneCredential(context, credential);
      },
      verificationFailed: (_) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The verification code could not be sent. Check the number and try again.',
            ),
          ),
        );
      },
      codeSent: (verificationId, _) async {
        if (!context.mounted) return;

        final code = await _showPhoneOtpDialog(context);

        if (code == null || !context.mounted) {
          return;
        }

        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code,
        );

        await _applyPhoneCredential(context, credential);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<String?> _showPhoneOtpDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;

        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: const Icon(Icons.password_rounded, size: 28),
          ),
          title: const Text('Verify phone number'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the six-digit code sent by SMS.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    counterText: '',
                  ),
                  validator: (value) {
                    return RegExp(r'^\d{6}$').hasMatch(value ?? '')
                        ? null
                        : 'Enter the complete six-digit code';
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _applyPhoneCredential(
    BuildContext context,
    PhoneAuthCredential credential,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in again to continue.')),
          );
        }
        return;
      }

      await user.updatePhoneNumber(credential);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phone': user.phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      setState(() {
        _phoneNumber = user.phoneNumber ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.changePhoneSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;

      final message = error.code == 'requires-recent-login'
          ? 'Sign in again before changing your phone number.'
          : 'The phone number could not be updated. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The phone number could not be updated. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _showThemeSelector(BuildContext context) async {
    final current = ref.read(themeModeProvider);

    final selected = await showModalBottomSheet<ThemeModeOption>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose appearance',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Use your device setting or choose a fixed theme.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in ThemeModeOption.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: option == current
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: option == current ? 2 : 1,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: option == current
                            ? scheme.primary
                            : scheme.primaryContainer,
                        foregroundColor: option == current
                            ? scheme.onPrimary
                            : scheme.onPrimaryContainer,
                        child: Icon(_themeModeIcon(option)),
                      ),
                      title: Text(
                        _themeModeLabel(option),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(_themeModeDescription(option)),
                      trailing: option == current
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext, option);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    await ref.read(themeModeProvider.notifier).setTheme(selected);
  }

  Future<void> _showSearchRadiusDialog(BuildContext context) async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Job search radius',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose how far Kazi should search for nearby opportunities.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final radius in AppConstants.searchRadii)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: radius == _searchRadius
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: radius == _searchRadius ? 2 : 1,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: radius == _searchRadius
                            ? scheme.primary
                            : scheme.primaryContainer,
                        foregroundColor: radius == _searchRadius
                            ? scheme.onPrimary
                            : scheme.onPrimaryContainer,
                        child: Text(
                          radius.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        '${radius.toStringAsFixed(0)} km',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: radius == 50
                          ? Text(AppStrings.entireNairobi)
                          : const Text('Search around your selected location'),
                      trailing: radius == _searchRadius
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext, radius);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setDouble(AppConstants.prefSearchRadius, selected);

    if (!context.mounted) return;

    setState(() {
      _searchRadius = selected;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Search radius set to '
          '${selected.toStringAsFixed(0)} km.',
        ),
      ),
    );
  }

  void _showFaq(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Frequently asked questions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Answers to common questions about jobs, payments, costs, and safety.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      children: [
                        _FaqItem(
                          question: AppStrings.faqHowWorksQ,
                          answer: AppStrings.faqHowWorksA,
                        ),
                        _FaqItem(
                          question: AppStrings.faqPaymentQ,
                          answer: AppStrings.faqPaymentA,
                        ),
                        _FaqItem(
                          question: AppStrings.faqCostQ,
                          answer: AppStrings.faqCostA,
                        ),
                        _FaqItem(
                          question: AppStrings.faqSafetyQ,
                          answer: AppStrings.faqSafetyA,
                        ),
                      ],
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

  Future<void> _launchWhatsApp(BuildContext context) async {
    final number = AppConstants.supportWhatsAppNumber.trim();

    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The support number is not available yet.'),
        ),
      );
      return;
    }

    final url = Uri.https('wa.me', '/$number', {
      'text': 'Hello, I need help with the Kazi app.',
    });

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp could not be opened on this device.'),
        ),
      );
    }
  }

  Future<void> _launchPlayStore(BuildContext context) async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.kazi.app',
    );

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Play could not be opened.')),
      );
    }
  }

  void _showTerms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: const Icon(Icons.policy_outlined),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Terms and privacy',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        AppStrings.termsContent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.6,
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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            child: const Icon(Icons.delete_forever_outlined, size: 28),
          ),
          title: const Text('Delete account?'),
          content: Text(
            AppStrings.settingsDeleteAccountDesc,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Keep account'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await AuthService.deleteAccount();

      if (context.mounted) {
        context.go('/role');
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The account could not be deleted. Sign in again and retry.',
          ),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 31,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.logout_rounded, size: 28),
          ),
          title: const Text('Sign out?'),
          content: Text(
            AppStrings.settingsLogoutConfirm,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await AuthService.signOut();

    if (context.mounted) {
      context.go('/role');
    }
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({required this.phoneNumber, required this.loading});

  final String phoneNumber;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
            AppTheme.teal,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -58,
            top: 24,
            child: Container(
              width: 196,
              height: 196,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 29, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -48,
            bottom: -57,
            child: Container(
              width: 146,
              height: 146,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                88,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.accentGold,
                      size: 25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Your Kazi, your way.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Manage your account, preferences, support, and security in one place.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          loading
                              ? 'Loading account…'
                              : phoneNumber.isEmpty
                              ? 'Complete your account'
                              : 'Account connected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

class _SettingsIntroduction extends StatelessWidget {
  const _SettingsIntroduction({
    required this.themeMode,
    required this.searchRadius,
  });

  final ThemeModeOption themeMode;
  final double searchRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account centre',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Review your most important settings and make changes whenever needed.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _SummaryChip(
              icon: _themeModeIcon(themeMode),
              label: _themeModeLabel(themeMode),
            ),
            _SummaryChip(
              icon: Icons.location_searching_rounded,
              label: '${searchRadius.toStringAsFixed(0)} km radius',
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: scheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(icon, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          ...List.generate(
            children.length,
            (index) => Column(
              children: [
                children[index],
                if (index < children.length - 1)
                  Divider(height: 1, indent: 72, color: scheme.outlineVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = destructive ? scheme.error : scheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: color.withValues(alpha: 0.11),
        foregroundColor: color,
        child: Icon(icon, size: 19),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: destructive ? scheme.error : null,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: destructive
                ? scheme.error.withValues(alpha: 0.8)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: destructive ? scheme.error : scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _AccountSecurityCard extends StatelessWidget {
  const _AccountSecurityCard({required this.onLogout, required this.onDelete});

  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  child: const Icon(Icons.shield_outlined),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account security',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onErrorContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Sign out safely or permanently remove your account.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.error.withValues(alpha: 0.2)),
          _SettingsActionTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'End the current session on this device',
            onTap: onLogout,
            destructive: true,
          ),
          Divider(
            height: 1,
            indent: 72,
            color: scheme.error.withValues(alpha: 0.2),
          ),
          _SettingsActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete account',
            subtitle: 'Permanently remove your Kazi data',
            onTap: onDelete,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.question_mark_rounded, size: 19),
        ),
        title: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Text(
            'Kazi',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Version 1.0.0+1',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _themeModeIcon(ThemeModeOption option) {
  switch (option) {
    case ThemeModeOption.system:
      return Icons.devices_rounded;
    case ThemeModeOption.light:
      return Icons.light_mode_rounded;
    case ThemeModeOption.dark:
      return Icons.dark_mode_rounded;
  }
}

String _themeModeLabel(ThemeModeOption option) {
  switch (option) {
    case ThemeModeOption.system:
      return 'Use device theme';
    case ThemeModeOption.light:
      return 'Light theme';
    case ThemeModeOption.dark:
      return 'Dark theme';
  }
}

String _themeModeDescription(ThemeModeOption option) {
  switch (option) {
    case ThemeModeOption.system:
      return 'Automatically follow your device appearance';
    case ThemeModeOption.light:
      return 'Always use the light appearance';
    case ThemeModeOption.dark:
      return 'Always use the dark appearance';
  }
}

String _maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');

  if (digits.length < 7) {
    return phone;
  }

  final ending = digits.substring(digits.length - 3);

  return '+254 ••• ••• $ending';
}
