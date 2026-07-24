import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../services/job_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requirementController = TextEditingController();
  final _durationController = TextEditingController(text: '1');

  final List<String> _requirements = [];

  String _selectedCategory = 'Cleaning';
  String _durationType = 'hours';
  int _durationValue = 1;

  DateTime _selectedDate = DateTime.now();
  bool _isUrgent = false;
  bool _isSubmitting = false;

  double? _selectedLat;
  double? _selectedLng;
  String? _selectedNeighborhood;
  String _employerPhone = '';

  List<String> get _categories => AppConstants.jobCategories;

  List<String> get _neighborhoods => AppConstants.nairobiNeighborhoods;

  @override
  void initState() {
    super.initState();
    _loadEmployerProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    _requirementController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployerProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = document.data();
      final storedPhone = data?['phone'] as String? ?? '';
      final neighborhood = data?['neighborhood'] as String?;

      if (storedPhone.isNotEmpty) {
        final localPhone = storedPhone
            .replaceAll(RegExp(r'\D'), '')
            .replaceFirst(RegExp(r'^254'), '');

        if (localPhone.length == 9) {
          _phoneController.text = localPhone;
          _employerPhone = localPhone;
        }
      }

      if (neighborhood != null && _neighborhoods.contains(neighborhood)) {
        _selectedNeighborhood = neighborhood;
        _updateCoordinates(neighborhood);
      }

      setState(() {});
    } catch (_) {
      // The form remains usable when profile prefill fails.
    }
  }

  void _addRequirement() {
    final requirement = _requirementController.text.trim();

    if (requirement.isEmpty) return;

    if (_requirements.length >= AppConstants.maxRequirements) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can add up to '
            '${AppConstants.maxRequirements} requirements.',
          ),
        ),
      );
      return;
    }

    if (_requirements.contains(requirement)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This requirement has already been added.'),
        ),
      );
      return;
    }

    setState(() {
      _requirements.add(requirement);
      _requirementController.clear();
    });
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select job start date',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;
    });
  }

  Future<void> _pickLocation() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _LocationPickerSheet(
          neighborhoods: _neighborhoods,
          selectedNeighborhood: _selectedNeighborhood,
        );
      },
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedNeighborhood = selected;
      _updateCoordinates(selected);
    });
  }

  void _updateCoordinates(String neighborhood) {
    const coordinates = <String, (double, double)>{
      'Westlands': (-1.2667, 36.8000),
      'CBD': (-1.2864, 36.8172),
      'Kilimani': (-1.2700, 36.8050),
      'Karen': (-1.3167, 36.7167),
      'Eastlands': (-1.2800, 36.8700),
      'Kasarani': (-1.2300, 36.8900),
      'Lavington': (-1.2867, 36.8167),
      'Parklands': (-1.2667, 36.8167),
      'Thika Rd': (-1.2600, 36.8600),
      'Kileleshwa': (-1.2600, 36.7900),
      'Langata': (-1.3167, 36.7833),
      'Hurlingham': (-1.2867, 36.8083),
      'Kensington': (-1.2917, 36.7983),
      'Spring Valley': (-1.2833, 36.8167),
      'Muthaiga': (-1.2467, 36.7933),
      'Runda': (-1.2333, 36.7667),
      'Gigiri': (-1.2450, 36.8033),
      'Loresho': (-1.2750, 36.7750),
      'Kitisuru': (-1.2400, 36.7800),
      'Nairobi': (-1.2921, 36.8219),
    };

    final coordinate = coordinates[neighborhood] ?? (-1.2921, 36.8219);

    _selectedLat = coordinate.$1;
    _selectedLng = coordinate.$2;
  }

  Map<String, double> get _paymentBreakdown {
    final salary = double.tryParse(_salaryController.text) ?? 0;

    return {
      'salary': salary,
      'employerPays': salary * (1 + AppConstants.employerFeePercent),
      'workerReceives': salary * (1 - AppConstants.workerFeePercent),
      'kaziFee': salary * AppConstants.platformFeePercent,
    };
  }

  Future<void> _submitJob() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedNeighborhood == null ||
        _selectedLat == null ||
        _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a location for this job.')),
      );
      return;
    }

    if (_employerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your M-Pesa phone number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw StateError('Not authenticated.');
      }

      final payment = _paymentBreakdown;
      final digits = _employerPhone.replaceAll(RegExp(r'\D'), '');

      final normalizedPhone = digits.startsWith('254')
          ? '+$digits'
          : digits.startsWith('0')
          ? '+254${digits.substring(1)}'
          : '+254$digits';

      final profileReference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final profile = await profileReference.get();

      final employerName =
          profile.data()?['name'] as String? ?? user.displayName ?? 'Employer';

      await profileReference.set({
        'name': employerName,
        'phone': normalizedPhone,
        'role': 'employer',
        'neighborhood': _selectedNeighborhood,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final jobReference = FirebaseFirestore.instance.collection('jobs').doc();

      await jobReference.set({
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'requirements': _requirements,
        'salaryKES': payment['salary'],
        'employerPaysKES': payment['employerPays'],
        'workerEarnsKES': payment['workerReceives'],
        'platformFeeKES': payment['kaziFee'],
        'duration': _durationValue,
        'durationType': _durationType,
        'startDate': Timestamp.fromDate(_selectedDate),
        'isUrgent': _isUrgent,
        'location': GeoPoint(_selectedLat!, _selectedLng!),
        'neighborhood': _selectedNeighborhood,
        'geohash': JobService.generateGeohash(_selectedLat!, _selectedLng!),
        'employerId': user.uid,
        'employerName': employerName,
        'employerPhone': normalizedPhone,
        'status': 'open',
        'paymentStatus': 'not_started',
        'applicantCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      await _showSuccessDialog(
        location: _selectedNeighborhood!,
        totalPayment: payment['employerPays'] ?? 0,
      );

      if (mounted) {
        context.go('/employer/job/${jobReference.id}');
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The job could not be posted. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showSuccessDialog({
    required String location,
    required double totalPayment,
  }) {
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
          title: const Text('Job published'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Workers near $location can now discover and apply for this job.',
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
                child: Column(
                  children: [
                    Text(
                      'PAYMENT AFTER HIRING',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'KES ${_formatAmount(totalPayment)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
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
              child: const Text('View job'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payment = _paymentBreakdown;

    return Scaffold(
      bottomNavigationBar: _PostJobActionBar(
        isSubmitting: _isSubmitting,
        onSubmit: _submitJob,
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 275,
            backgroundColor: AppTheme.primaryGreenDark,
            foregroundColor: Colors.white,
            title: Text('Post a job'),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _PostJobHero(),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Widgets.sectionHeader(
                      context: context,
                      title: 'Create an opportunity',
                      subtitle:
                          'Share clear job details so nearby workers can decide and apply quickly.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FormSection(
                      number: '01',
                      icon: Icons.edit_note_rounded,
                      title: 'Job details',
                      description: 'Explain what needs to be done.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Job title',
                              hintText: 'Example: Deep house cleaning',
                              prefixIcon: Icon(Icons.work_outline_rounded),
                            ),
                            validator: (value) {
                              final title = value?.trim() ?? '';

                              if (title.isEmpty) {
                                return 'Enter a job title';
                              }

                              if (title.length < 4) {
                                return 'Use at least 4 characters';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CATEGORY',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.7,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _categories.map((category) {
                              return ChoiceChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                avatar: Icon(_categoryIcon(category), size: 17),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormField(
                            controller: _descriptionController,
                            minLines: 5,
                            maxLines: 8,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Job description',
                              hintText:
                                  'Describe the work, responsibilities, tools, and expected outcome.',
                              alignLabelWithHint: true,
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 94),
                                child: Icon(Icons.description_outlined),
                              ),
                            ),
                            validator: (value) {
                              final description = value?.trim() ?? '';

                              if (description.isEmpty) {
                                return 'Enter a job description';
                              }

                              if (description.length < 20) {
                                return 'Add a little more detail';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FormSection(
                      number: '02',
                      icon: Icons.fact_check_outlined,
                      title: 'Requirements',
                      description: 'List skills, tools, or experience needed.',
                      optional: true,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _requirementController,
                                  textInputAction: TextInputAction.done,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Example: Bring cleaning supplies',
                                    prefixIcon: Icon(Icons.add_task_rounded),
                                  ),
                                  onSubmitted: (_) {
                                    _addRequirement();
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton.filled(
                                tooltip: 'Add requirement',
                                onPressed: _addRequirement,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                          if (_requirements.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            for (
                              var index = 0;
                              index < _requirements.length;
                              index++
                            ) ...[
                              _RequirementItem(
                                number: index + 1,
                                requirement: _requirements[index],
                                onRemove: () {
                                  _removeRequirement(index);
                                },
                              ),
                              if (index < _requirements.length - 1)
                                const SizedBox(height: AppSpacing.xs),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FormSection(
                      number: '03',
                      icon: Icons.payments_outlined,
                      title: 'Budget and duration',
                      description:
                          'Set fair compensation and expected working time.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _salaryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Job budget',
                              hintText: '0',
                              prefixText: 'KES ',
                              prefixIcon: Icon(
                                Icons.account_balance_wallet_outlined,
                              ),
                            ),
                            validator: (value) {
                              final amount = double.tryParse(
                                value?.trim() ?? '',
                              );

                              if (amount == null || amount <= 0) {
                                return 'Enter a valid job budget';
                              }

                              return null;
                            },
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 380;

                              final durationField = TextFormField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  prefixIcon: Icon(Icons.timelapse_rounded),
                                ),
                                validator: (value) {
                                  final duration = int.tryParse(
                                    value?.trim() ?? '',
                                  );

                                  if (duration == null || duration <= 0) {
                                    return 'Enter a valid duration';
                                  }

                                  return null;
                                },
                                onChanged: (value) {
                                  final duration = int.tryParse(value);

                                  if (duration != null && duration > 0) {
                                    setState(() {
                                      _durationValue = duration;
                                    });
                                  }
                                },
                              );

                              final typeSelector = SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'hours',
                                    label: Text('Hours'),
                                    icon: Icon(Icons.schedule_rounded),
                                  ),
                                  ButtonSegment(
                                    value: 'days',
                                    label: Text('Days'),
                                    icon: Icon(Icons.calendar_view_day_rounded),
                                  ),
                                ],
                                selected: {_durationType},
                                onSelectionChanged: (selection) {
                                  setState(() {
                                    _durationType = selection.first;
                                  });
                                },
                              );

                              if (narrow) {
                                return Column(
                                  children: [
                                    durationField,
                                    const SizedBox(height: AppSpacing.md),
                                    SizedBox(
                                      width: double.infinity,
                                      child: typeSelector,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: durationField),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: typeSelector),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FormSection(
                      number: '04',
                      icon: Icons.event_available_outlined,
                      title: 'Schedule and location',
                      description:
                          'Tell workers when and where the job starts.',
                      child: Column(
                        children: [
                          _SelectionTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Start date',
                            value: DateFormat(
                              'EEEE, d MMMM yyyy',
                            ).format(_selectedDate),
                            onTap: _selectDate,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _SelectionTile(
                            icon: Icons.location_on_outlined,
                            label: 'Job location',
                            value:
                                _selectedNeighborhood ??
                                'Choose a neighborhood',
                            placeholder: _selectedNeighborhood == null,
                            onTap: _pickLocation,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _UrgencyControl(
                            value: _isUrgent,
                            onChanged: (value) {
                              setState(() {
                                _isUrgent = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FormSection(
                      number: '05',
                      icon: Icons.phone_iphone_rounded,
                      title: 'Payment contact',
                      description:
                          'This number receives the M-Pesa prompt after you select a worker.',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        textInputAction: TextInputAction.done,
                        maxLength: 9,
                        decoration: const InputDecoration(
                          labelText: 'M-Pesa phone number',
                          prefixText: '+254 ',
                          counterText: '',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                          helperText: 'Enter the 9 digits after +254.',
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';

                          if (phone.isEmpty) {
                            return 'Enter a phone number';
                          }

                          if (phone.length != 9) {
                            return 'Enter exactly 9 digits';
                          }

                          if (!RegExp(r'^[17]\d{8}$').hasMatch(phone)) {
                            return 'Enter a valid Kenyan mobile number';
                          }

                          return null;
                        },
                        onChanged: (value) {
                          _employerPhone = value.trim();
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PaymentSummaryCard(payment: payment),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostJobHero extends StatelessWidget {
  const _PostJobHero();

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
            right: -54,
            top: 22,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 28, color: Colors.white24),
              ),
            ),
          ),
          Positioned(
            left: -45,
            bottom: -55,
            child: Container(
              width: 142,
              height: 142,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white10,
              ),
            ),
          ),
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                86,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CREATE AN OPPORTUNITY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.35,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Find the right worker.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Post once. Reach trusted workers nearby.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: [
                      _HeroStep(
                        icon: Icons.edit_note_rounded,
                        label: 'Describe',
                      ),
                      _HeroConnector(),
                      _HeroStep(icon: Icons.groups_outlined, label: 'Match'),
                      _HeroConnector(),
                      _HeroStep(icon: Icons.how_to_reg_rounded, label: 'Hire'),
                    ],
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

class _HeroStep extends StatelessWidget {
  const _HeroStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, size: 19, color: AppTheme.accentGold),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroConnector extends StatelessWidget {
  const _HeroConnector();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: 20,
        ),
        color: Colors.white24,
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.optional = false,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, color: scheme.onPrimaryContainer, size: 23),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 17,
                          height: 17,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Text(
                            number,
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (optional) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                'Optional',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({
    required this.number,
    required this.requirement,
    required this.onRemove,
  });

  final int number;
  final String requirement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              requirement,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove requirement',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: scheme.error, size: 19),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              child: Icon(icon, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: placeholder
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontWeight: placeholder
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _UrgencyControl extends StatelessWidget {
  const _UrgencyControl({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: value
            ? scheme.errorContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value
              ? scheme.error.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: CircleAvatar(
          backgroundColor: value
              ? scheme.error
              : scheme.surfaceContainerHighest,
          foregroundColor: value ? scheme.onError : scheme.onSurfaceVariant,
          child: const Icon(Icons.bolt_rounded),
        ),
        title: Text(
          'Mark as urgent',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Use for work needed today or as soon as possible.',
        ),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.payment});

  final Map<String, double> payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white12,
                foregroundColor: AppTheme.accentGold,
                child: Icon(Icons.receipt_long_outlined),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      'You pay only after selecting a worker.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _PaymentRow(label: 'Job budget', value: payment['salary'] ?? 0),
          const SizedBox(height: AppSpacing.sm),
          _PaymentRow(
            label: 'Worker receives',
            value: payment['workerReceives'] ?? 0,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PaymentRow(label: 'Platform fee', value: payment['kaziFee'] ?? 0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: Colors.white24),
          ),
          _PaymentRow(
            label: 'Total after hiring',
            value: payment['employerPays'] ?? 0,
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final double value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: highlighted ? Colors.white : Colors.white70,
              fontSize: highlighted ? 14 : 13,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          'KES ${_formatAmount(value)}',
          style: TextStyle(
            color: highlighted ? AppTheme.accentGold : Colors.white,
            fontSize: highlighted ? 21 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PostJobActionBar extends StatelessWidget {
  const _PostJobActionBar({required this.isSubmitting, required this.onSubmit});

  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
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
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(isSubmitting ? 'Publishing job…' : 'Publish job'),
          ),
        ),
      ),
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.neighborhoods,
    required this.selectedNeighborhood,
  });

  final List<String> neighborhoods;
  final String? selectedNeighborhood;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final filtered = widget.neighborhoods
        .where(
          (neighborhood) =>
              neighborhood.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose job location',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Nearby workers will use this location when discovering the job.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search neighborhoods',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No matching locations.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: scheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final neighborhood = filtered[index];
                          final selected =
                              neighborhood == widget.selectedNeighborhood;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? scheme.primary
                                  : scheme.primaryContainer,
                              foregroundColor: selected
                                  ? scheme.onPrimary
                                  : scheme.onPrimaryContainer,
                              child: Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.location_on_outlined,
                              ),
                            ),
                            title: Text(neighborhood),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.pop(context, neighborhood);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'plumbing':
      return Icons.plumbing_rounded;
    case 'electrical':
      return Icons.electrical_services_rounded;
    case 'delivery':
      return Icons.delivery_dining_rounded;
    case 'security':
      return Icons.security_rounded;
    case 'cooking':
      return Icons.restaurant_rounded;
    case 'childcare':
      return Icons.child_care_rounded;
    case 'painting':
      return Icons.format_paint_rounded;
    case 'carpentry':
      return Icons.carpenter_rounded;
    case 'gardening':
      return Icons.yard_rounded;
    case 'driving':
      return Icons.drive_eta_rounded;
    case 'events':
      return Icons.event_rounded;
    case 'casual labour':
      return Icons.construction_rounded;
    default:
      return Icons.work_rounded;
  }
}

String _formatAmount(double amount) {
  return NumberFormat('#,##0').format(amount);
}
