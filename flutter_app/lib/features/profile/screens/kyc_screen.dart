import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/kazi_button.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _idCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaziTheme.background,
      appBar: AppBar(title: const Text('Get Verified')),
      body: Padding(
        padding: const EdgeInsets.all(KaziSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(KaziSpacing.md),
              decoration: BoxDecoration(
                color: KaziTheme.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KaziTheme.info.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: KaziTheme.info, size: 20),
                  SizedBox(width: KaziSpacing.sm),
                  Expanded(
                    child: Text(
                      'Verified workers get 3x more job matches and higher employer trust.',
                      style: KaziText.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KaziSpacing.xl),
            Text('National ID Number', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            TextField(
              controller: _idCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 12345678',
                prefixIcon: Icon(Icons.badge_outlined, color: KaziTheme.textHint),
              ),
            ),
            const SizedBox(height: KaziSpacing.lg),
            Text('ID Photo', style: KaziText.label),
            const SizedBox(height: KaziSpacing.sm),
            GestureDetector(
              onTap: () {}, // TODO: Image picker
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: KaziTheme.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KaziTheme.border, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: KaziTheme.textHint, size: 32),
                    SizedBox(height: 8),
                    Text('Tap to upload ID photo', style: KaziText.caption),
                  ],
                ),
              ),
            ),
            const Spacer(),
            KaziButton(
              label: 'Submit for Verification',
              onPressed: () {},
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
