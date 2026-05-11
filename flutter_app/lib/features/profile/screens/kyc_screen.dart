import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/services/api_client.dart';
import '../../../shared/widgets/kazi_button.dart';
import '../bloc/kyc_bloc.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KYCBloc(context.read<ApiClient>()),
      child: const KycView(),
    );
  }
}

class KycView extends StatefulWidget {
  const KycView({super.key});

  @override
  State<KycView> createState() => _KycViewState();
}

class _KycViewState extends State<KycView> {
  final _idCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _idPhoto;

  Future<void> _pickImage() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _idPhoto = photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KYCBloc, KYCState>(
      listener: (context, state) {
        if (state is KYCSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: KaziTheme.success),
          );
          Navigator.pop(context);
        } else if (state is KYCError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: KaziTheme.error),
          );
        }
      },
      child: Scaffold(
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
                    const Icon(Icons.info_outline_rounded, color: KaziTheme.info, size: 20),
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
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: KaziTheme.surfaceWarm,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KaziTheme.border),
                    image: _idPhoto != null
                        ? DecorationImage(
                            image: FileImage(File(_idPhoto!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _idPhoto == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: KaziTheme.textHint, size: 32),
                            const SizedBox(height: 8),
                            Text('Tap to upload ID photo', style: KaziText.caption),
                          ],
                        )
                      : null,
                ),
              ),
              const Spacer(),
              BlocBuilder<KYCBloc, KYCState>(
                builder: (context, state) {
                  return KaziButton(
                    label: 'Submit for Verification',
                    isLoading: state is KYCLoading,
                    onPressed: () {
                      if (_idCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your ID number')),
                        );
                        return;
                      }
                      context.read<KYCBloc>().add(SubmitKYCEvent(
                            idNumber: _idCtrl.text,
                            idPhotoPath: _idPhoto?.path,
                          ));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
