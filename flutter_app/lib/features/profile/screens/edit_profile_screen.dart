import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/kazi_button.dart';

// ─── Edit Profile ──────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(KaziSpacing.md),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: KaziTheme.surfaceWarm,
                  child: Icon(Icons.person_rounded, size: 44, color: KaziTheme.textHint),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      color: KaziTheme.primary, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KaziSpacing.xl),
          Text('First Name', style: KaziText.label),
          const SizedBox(height: KaziSpacing.sm),
          TextField(controller: _firstCtrl, decoration: const InputDecoration(hintText: 'First name')),
          const SizedBox(height: KaziSpacing.md),
          Text('Last Name', style: KaziText.label),
          const SizedBox(height: KaziSpacing.sm),
          TextField(controller: _lastCtrl, decoration: const InputDecoration(hintText: 'Last name')),
          const SizedBox(height: KaziSpacing.md),
          Text('Email (optional)', style: KaziText.label),
          const SizedBox(height: KaziSpacing.sm),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'your@email.com')),
          const SizedBox(height: KaziSpacing.md),
          Text('Bio', style: KaziText.label),
          const SizedBox(height: KaziSpacing.sm),
          TextField(controller: _bioCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Tell employers about yourself...')),
          const SizedBox(height: KaziSpacing.xl),
          KaziButton(label: 'Save Changes', onPressed: () {}, isLoading: _isLoading),
        ],
      ),
    );
  }
}
