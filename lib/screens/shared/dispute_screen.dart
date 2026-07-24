import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/dispute_service.dart';
import '../../utils/app_theme.dart';

enum DisputeStep { selectReason, addEvidence, review }

enum DisputeReason {
  workerNoShow(
    label: 'Worker did not show up',
    description: 'The worker failed to arrive at the agreed time or location.',
    icon: Icons.person_off_outlined,
  ),
  poorQuality(
    label: 'Work quality was poor',
    description: 'The completed work did not meet the agreed requirements.',
    icon: Icons.build_circle_outlined,
  ),
  noPayment(
    label: 'Payment was not received',
    description: 'The agreed payment has not reached the worker or wallet.',
    icon: Icons.payments_outlined,
  ),
  abusive(
    label: 'Abusive or unsafe behaviour',
    description:
        'The other party used threatening, abusive, or unsafe conduct.',
    icon: Icons.report_outlined,
  ),
  wrongDescription(
    label: 'Job differed from the description',
    description:
        'The actual task, location, or conditions were materially different.',
    icon: Icons.assignment_late_outlined,
  ),
  other(
    label: 'Something else',
    description: 'Report another issue that requires support review.',
    icon: Icons.more_horiz_rounded,
  );

  const DisputeReason({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({
    super.key,
    required this.jobId,
    required this.applicationId,
  });

  final String jobId;
  final String applicationId;

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<XFile> _photos = [];
  final List<String> _uploadedUrls = [];

  DisputeStep _currentStep = DisputeStep.selectReason;
  DisputeReason? _selectedReason;

  bool _isSubmitting = false;
  int _uploadedPhotoCount = 0;

  int get _stepNumber => _currentStep.index + 1;

  double get _progress => _stepNumber / DisputeStep.values.length;

  bool get _canContinue {
    switch (_currentStep) {
      case DisputeStep.selectReason:
        return _selectedReason != null;
      case DisputeStep.addEvidence:
        return _photos.length <= 3 &&
            _descriptionController.text.trim().length <= 300;
      case DisputeStep.review:
        return _selectedReason != null;
    }
  }

  String get _primaryActionLabel {
    switch (_currentStep) {
      case DisputeStep.selectReason:
        return 'Continue';
      case DisputeStep.addEvidence:
        return 'Review report';
      case DisputeStep.review:
        return 'Submit report';
    }
  }

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_handleDescriptionChanged);
  }

  void _handleDescriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_handleDescriptionChanged);
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can attach a maximum of three photos.'),
        ),
      );
      return;
    }

    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (photo == null || !mounted) {
        return;
      }

      setState(() {
        _photos.add(photo);
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The photo could not be selected. Please try again.'),
        ),
      );
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _moveForward() {
    if (!_canContinue || _isSubmitting) {
      return;
    }

    switch (_currentStep) {
      case DisputeStep.selectReason:
        setState(() {
          _currentStep = DisputeStep.addEvidence;
        });
      case DisputeStep.addEvidence:
        setState(() {
          _currentStep = DisputeStep.review;
        });
      case DisputeStep.review:
        _submitDispute();
    }
  }

  void _moveBack() {
    if (_isSubmitting) return;

    switch (_currentStep) {
      case DisputeStep.selectReason:
        Navigator.pop(context);
      case DisputeStep.addEvidence:
        setState(() {
          _currentStep = DisputeStep.selectReason;
        });
      case DisputeStep.review:
        setState(() {
          _currentStep = DisputeStep.addEvidence;
        });
    }
  }

  Future<void> _submitDispute() async {
    final user = FirebaseAuth.instance.currentUser;
    final reason = _selectedReason;

    if (user == null || reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in again before submitting this report.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadedPhotoCount = 0;
    });

    try {
      _uploadedUrls.clear();

      for (final photo in _photos) {
        final reference = FirebaseStorage.instance.ref().child(
          'disputes/${widget.jobId}/${user.uid}/'
          '${DateTime.now().microsecondsSinceEpoch}_${photo.name}',
        );

        final upload = await reference.putFile(File(photo.path));

        _uploadedUrls.add(await upload.ref.getDownloadURL());

        if (mounted) {
          setState(() {
            _uploadedPhotoCount++;
          });
        }
      }

      await DisputeService.fileDispute(
        jobId: widget.jobId,
        applicationId: widget.applicationId,
        reason: reason.name,
        reasonLabel: reason.label,
        description: _descriptionController.text.trim(),
        photoUrls: _uploadedUrls,
      );

      if (!mounted) return;

      await _showSuccessDialog();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The report could not be submitted. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: CircleAvatar(
            radius: 34,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: const Icon(Icons.task_alt_rounded, size: 32),
          ),
          title: const Text('Report submitted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kazi support has received your report and will review the job records and evidence.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Most reports are reviewed within 24 hours.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _currentStep == DisputeStep.selectReason && !_isSubmitting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _moveBack();
        }
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(
          title: const Text('Report a dispute'),
          leading: IconButton(
            tooltip: _currentStep == DisputeStep.selectReason
                ? 'Close'
                : 'Previous step',
            onPressed: _isSubmitting ? null : _moveBack,
            icon: Icon(
              _currentStep == DisputeStep.selectReason
                  ? Icons.close_rounded
                  : Icons.arrow_back_rounded,
            ),
          ),
        ),
        bottomNavigationBar: _DisputeActionBar(
          step: _currentStep,
          enabled: _canContinue,
          submitting: _isSubmitting,
          uploadedPhotoCount: _uploadedPhotoCount,
          totalPhotos: _photos.length,
          actionLabel: _primaryActionLabel,
          onBack: _moveBack,
          onContinue: _moveForward,
        ),
        body: Column(
          children: [
            _DisputeProgressHeader(step: _currentStep, progress: _progress),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: switch (_currentStep) {
                  DisputeStep.selectReason => _ReasonStep(
                    key: const ValueKey('reason-step'),
                    selectedReason: _selectedReason,
                    onSelected: (reason) {
                      setState(() {
                        _selectedReason = reason;
                      });
                    },
                  ),
                  DisputeStep.addEvidence => _EvidenceStep(
                    key: const ValueKey('evidence-step'),
                    photos: _photos,
                    controller: _descriptionController,
                    onAddPhoto: _pickPhoto,
                    onRemovePhoto: _removePhoto,
                  ),
                  DisputeStep.review => _ReviewStep(
                    key: const ValueKey('review-step'),
                    reason: _selectedReason!,
                    photos: _photos,
                    description: _descriptionController.text.trim(),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeProgressHeader extends StatelessWidget {
  const _DisputeProgressHeader({required this.step, required this.progress});

  final DisputeStep step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = switch (step) {
      DisputeStep.selectReason => 'Tell us what happened',
      DisputeStep.addEvidence => 'Add supporting details',
      DisputeStep.review => 'Review before submitting',
    };

    final description = switch (step) {
      DisputeStep.selectReason =>
        'Choose the option that best describes the problem.',
      DisputeStep.addEvidence =>
        'Photos and clear details help support resolve the issue.',
      DisputeStep.review => 'Confirm that the report is accurate and complete.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
            AppTheme.teal,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${step.index + 1}',
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${step.index + 1} OF 3',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: Colors.white24,
                color: AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}% complete',
              style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.72),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonStep extends StatelessWidget {
  const _ReasonStep({
    super.key,
    required this.selectedReason,
    required this.onSelected,
  });

  final DisputeReason? selectedReason;
  final ValueChanged<DisputeReason> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Select a reason',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your selection helps route the report to the right support process.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final reason in DisputeReason.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _ReasonCard(
              reason: reason,
              selected: selectedReason == reason,
              onTap: () {
                onSelected(reason);
              },
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        const _ConfidentialityNotice(),
      ],
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final DisputeReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedContainer(
      duration: AppMotion.standard,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: selected
                      ? scheme.primary
                      : scheme.primaryContainer,
                  foregroundColor: selected
                      ? scheme.onPrimary
                      : scheme.onPrimaryContainer,
                  child: Icon(reason.icon, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        reason.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? scheme.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outline,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: scheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({
    super.key,
    required this.photos,
    required this.controller,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final TextEditingController controller;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Supporting evidence',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Evidence is optional, but it can help support understand and resolve the issue faster.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PhotoEvidenceCard(
          photos: photos,
          onAddPhoto: onAddPhoto,
          onRemovePhoto: onRemovePhoto,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: const Icon(Icons.notes_rounded),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Describe what happened',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Include dates, agreements, and relevant actions.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: controller,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Explain the issue clearly and factually…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _EvidenceGuidanceCard(),
      ],
    );
  }
}

class _PhotoEvidenceCard extends StatelessWidget {
  const _PhotoEvidenceCard({
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photos',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${photos.length} of 3 attached',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: photos.length >= 3 ? null : onAddPhoto,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Image.file(
                            File(photos[index].path),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: scheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: scheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.xxs,
                        right: AppSpacing.xxs,
                        child: IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Remove photo',
                          onPressed: () {
                            onRemovePhoto(index);
                          },
                          icon: const Icon(Icons.close_rounded, size: 17),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.reason,
    required this.photos,
    required this.description,
  });

  final DisputeReason reason;
  final List<XFile> photos;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Report summary',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Review the information below before sending it to Kazi support.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewSummaryCard(
          icon: reason.icon,
          label: 'Reason',
          value: reason.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ReviewSummaryCard(
          icon: Icons.photo_library_outlined,
          label: 'Evidence',
          value: photos.isEmpty
              ? 'No photos attached'
              : '${photos.length} photo'
                    '${photos.length == 1 ? '' : 's'} attached',
        ),
        const SizedBox(height: AppSpacing.sm),
        _ReviewSummaryCard(
          icon: Icons.notes_rounded,
          label: 'Details',
          value: description.isEmpty
              ? 'No additional details provided'
              : description,
        ),
        const SizedBox(height: AppSpacing.md),
        const _TransactionFreezeNotice(),
        const SizedBox(height: AppSpacing.md),
        const _AccuracyConfirmationCard(),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidentialityNotice extends StatelessWidget {
  const _ConfidentialityNotice();

  @override
  Widget build(BuildContext context) {
    return _InformationNotice(
      icon: Icons.lock_outline_rounded,
      title: 'Handled privately',
      message:
          'Your report is shared only with authorised Kazi support staff and the parties involved where necessary.',
    );
  }
}

class _EvidenceGuidanceCard extends StatelessWidget {
  const _EvidenceGuidanceCard();

  @override
  Widget build(BuildContext context) {
    return const _InformationNotice(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Useful evidence',
      message:
          'Upload clear images that directly relate to the job. Avoid unrelated personal information.',
    );
  }
}

class _AccuracyConfirmationCard extends StatelessWidget {
  const _AccuracyConfirmationCard();

  @override
  Widget build(BuildContext context) {
    return const _InformationNotice(
      icon: Icons.fact_check_outlined,
      title: 'Submit accurate information',
      message:
          'False or misleading reports may affect account access and platform trust.',
    );
  }
}

class _InformationNotice extends StatelessWidget {
  const _InformationNotice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionFreezeNotice extends StatelessWidget {
  const _TransactionFreezeNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppTheme.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Related transactions may be paused',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Wallet transactions linked to this job may be temporarily frozen until the dispute is resolved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.warning,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeActionBar extends StatelessWidget {
  const _DisputeActionBar({
    required this.step,
    required this.enabled,
    required this.submitting,
    required this.uploadedPhotoCount,
    required this.totalPhotos,
    required this.actionLabel,
    required this.onBack,
    required this.onContinue,
  });

  final DisputeStep step;
  final bool enabled;
  final bool submitting;
  final int uploadedPhotoCount;
  final int totalPhotos;
  final String actionLabel;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String? statusText;

    if (submitting && totalPhotos > 0) {
      statusText = 'Uploading evidence $uploadedPhotoCount of $totalPhotos';
    } else if (submitting) {
      statusText = 'Submitting report';
    }

    return Material(
      elevation: 10,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statusText != null) ...[
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: [
                  if (step != DisputeStep.selectReason) ...[
                    OutlinedButton(
                      onPressed: submitting ? null : onBack,
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: enabled && !submitting ? onContinue : null,
                      icon: submitting
                          ? const SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              step == DisputeStep.review
                                  ? Icons.send_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                      label: Text(submitting ? 'Submitting…' : actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
