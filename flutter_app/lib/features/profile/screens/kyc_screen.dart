import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/kazi_button.dart';


class KycScreen extends StatefulWidget {
  const KycScreen({super.key});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _picker = ImagePicker();
  String? _idImageBase64;
  String? _selfieBase64;
  bool _isLoading = false;

  Future<void> _pickImage(bool isSelfie) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        if (isSelfie) {
          _selfieBase64 = base64;
        } else {
          _idImageBase64 = base64;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_idImageBase64 == null || _selfieBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture both ID and selfie photos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiClient>();
      await api.submitKYC({
        'id_image': _idImageBase64!,
        'selfie_image': _selfieBase64!,
        'id_type': 'national_id',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted. Results will be sent shortly.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePicker(String label, String? imageBase64, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KaziText.label),
        const SizedBox(height: KaziSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: imageBase64 != null ? KaziTheme.success.withOpacity(0.1) : KaziTheme.surfaceWarm,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: imageBase64 != null ? KaziTheme.success : KaziTheme.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  imageBase64 != null ? Icons.check_circle : Icons.camera_alt_outlined,
                  color: imageBase64 != null ? KaziTheme.success : KaziTheme.textHint,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  imageBase64 != null ? '$label Captured' : 'Tap to take $label photo',
                  style: KaziText.caption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
                  const SizedBox(width: KaziSpacing.sm),
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
            _buildImagePicker('ID Photo', _idImageBase64, () => _pickImage(false)),
            const SizedBox(height: KaziSpacing.lg),
            _buildImagePicker('Selfie Photo', _selfieBase64, () => _pickImage(true)),
            const Spacer(),
            KaziButton(
              label: 'Submit for Verification',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}