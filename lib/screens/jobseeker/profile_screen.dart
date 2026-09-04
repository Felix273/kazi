import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_constants.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widget_builder.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId, this.roleHint});

  final String? userId;
  final String? roleHint;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;
  bool _uploadingId = false;

  String? get _profileId =>
      widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

  bool get _isCurrentUser =>
      _profileId != null &&
      _profileId == FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final profileId = _profileId;

    if (profileId == null) {
      return Scaffold(
        bottomNavigationBar: _ProfileNavigation(
          isEmployer: widget.roleHint == AppConstants.roleEmployer,
        ),
        body: _ProfileStateView(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view your profile',
          message:
              'Your Kazi profile and account controls are available after signing in.',
          actionLabel: 'Continue to sign in',
          onAction: () => context.go('/role'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profileId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: _ProfileLoadingView());
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: _ProfileStateView(
              icon: Icons.cloud_off_rounded,
              title: 'Profile is unavailable',
              message:
                  'Check your connection and try loading this profile again.',
            ),
          );
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return const Scaffold(
            body: _ProfileStateView(
              icon: Icons.person_search_outlined,
              title: 'Profile not found',
              message:
                  'This Kazi profile may have been removed or is no longer available.',
            ),
          );
        }

        final user = UserModel.fromMap(data, profileId);
        final isEmployer = user.role == 'employer';

        return Scaffold(
          bottomNavigationBar: _isCurrentUser
              ? _ProfileNavigation(isEmployer: isEmployer)
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(profileId)
                  .get(const GetOptions(source: Source.server));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 348,
                  automaticallyImplyLeading: !_isCurrentUser,
                  backgroundColor: AppTheme.primaryGreenDark,
                  foregroundColor: Colors.white,
                  title: Text(_isCurrentUser ? 'Profile' : _displayName(user)),
                  actions: [
                    if (_isCurrentUser)
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () => _showEditProfile(user),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _ProfileHero(
                      user: user,
                      isCurrentUser: _isCurrentUser,
                      uploadingPhoto: _uploadingPhoto,
                      onChangePhoto: _pickAndUploadPhoto,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _ProfileStatsCard(user: user),
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
                    child: _ProfileSectionCard(
                      title: 'Profile details',
                      icon: Icons.person_outline_rounded,
                      child: Column(
                        children: [
                          _ProfileInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: user.phone.trim().isEmpty
                                ? 'Not provided'
                                : user.phone.trim(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _ProfileInfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: user.neighborhood?.trim().isNotEmpty == true
                                ? user.neighborhood!.trim()
                                : 'Not provided',
                          ),
                          if (user.email?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.md),
                            _ProfileInfoRow(
                              icon: Icons.mail_outline_rounded,
                              label: 'Email',
                              value: user.email!.trim(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (user.bio?.trim().isNotEmpty == true)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _ProfileSectionCard(
                        title: 'About',
                        icon: Icons.notes_rounded,
                        child: Text(
                          user.bio!.trim(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(height: 1.55),
                        ),
                      ),
                    ),
                  ),
                if ((user.skills ?? const <String>[]).isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _ProfileSectionCard(
                        title: 'Skills',
                        icon: Icons.workspace_premium_outlined,
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: user.skills!
                              .map(
                                (skill) => Chip(
                                  avatar: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 17,
                                  ),
                                  label: Text(skill),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                if (_isCurrentUser)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _AccountCard(
                        user: user,
                        uploadingId: _uploadingId,
                        onAvailabilityChanged: _updateAvailability,
                        onVerifyIdentity: () => _showIdVerification(user),
                        onOpenNotifications: () {
                          context.push('/settings/notifications');
                        },
                        onSignOut: _signOut,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateAvailability(bool value) async {
    try {
      await ProfileService.setAvailability(value);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability could not be updated. Please try again.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();

      if (!mounted) return;

      context.go('/role');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You could not be signed out. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditProfile(UserModel user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final neighborhoodController = TextEditingController(
      text: user.neighborhood ?? '',
    );
    final bioController = TextEditingController(text: user.bio ?? '');
    final skillsController = TextEditingController(
      text: (user.skills ?? const <String>[]).join(', '),
    );

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            final theme = Theme.of(sheetContext);
            final scheme = theme.colorScheme;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xl,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: const Icon(
                        Icons.manage_accounts_outlined,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Edit profile',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Keep your information accurate so opportunities match you better.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value?.trim().isEmpty == true) {
                          return 'Your full name is required';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: phoneController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        helperText: 'Phone changes require OTP verification.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: neighborhoodController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Neighborhood or area',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: skillsController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Skills',
                        hintText: 'Electrical, plumbing, delivery',
                        helperText: 'Separate multiple skills with commas.',
                        prefixIcon: Icon(Icons.workspace_premium_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: bioController,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'About you',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }

                              FocusManager.instance.primaryFocus?.unfocus();

                              setSheetState(() => saving = true);

                              try {
                                final skills = skillsController.text
                                    .split(',')
                                    .map((value) => value.trim())
                                    .where((value) => value.isNotEmpty)
                                    .toSet()
                                    .toList();

                                await ProfileService.updateProfile(
                                  user.copyWith(
                                    name: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    neighborhood: neighborhoodController.text
                                        .trim(),
                                    bio: bioController.text.trim(),
                                    skills: skills,
                                  ),
                                );

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Your profile has been saved.',
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              } catch (_) {
                                if (sheetContext.mounted) {
                                  setSheetState(() => saving = false);
                                }

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Your profile could not be saved. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: saving
                            ? const SizedBox.square(
                                key: ValueKey('saving'),
                                dimension: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Save changes',
                                key: ValueKey('save-label'),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    neighborhoodController.dispose();
    bioController.dispose();
    skillsController.dispose();
  }

  Future<void> _showIdVerification(UserModel user) async {
    final idController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    XFile? idImage;
    bool selecting = false;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setSheetState) {
            final theme = Theme.of(sheetContext);
            final scheme = theme.colorScheme;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.xl,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: const Icon(Icons.badge_outlined, size: 28),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Verify identity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Submit your national ID number and a clear image of the document.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: idController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'National ID number',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        final digits =
                            value?.replaceAll(RegExp(r'\D'), '') ?? '';

                        if (digits.length < 5 || digits.length > 12) {
                          return 'Enter a valid ID number';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: selecting
                          ? null
                          : () async {
                              setSheetState(() => selecting = true);

                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                                maxWidth: 1800,
                              );

                              if (!sheetContext.mounted) {
                                return;
                              }

                              setSheetState(() {
                                idImage = picked;
                                selecting = false;
                              });
                            },
                      icon: selecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        idImage == null
                            ? 'Choose ID image'
                            : 'Choose a different image',
                      ),
                    ),
                    if (idImage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        height: 160,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Image.file(
                          File(idImage!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Center(
                              child: Text(
                                idImage!.name,
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(
                          alpha: 0.62,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: scheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Your identity document is used only for account verification.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSecondaryContainer,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        if (idImage == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Choose a clear image of your identity document.',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(sheetContext, true);
                      },
                      child: const Text('Submit for review'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted != true || idImage == null || !mounted) {
      idController.dispose();
      return;
    }

    setState(() => _uploadingId = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final extension = idImage!.name.contains('.')
          ? idImage!.name.split('.').last.toLowerCase()
          : 'jpg';

      final reference = FirebaseStorage.instance.ref(
        'identity/$userId/'
        'id_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      await reference.putFile(File(idImage!.path));
      final imageUrl = await reference.getDownloadURL();

      await ProfileService.uploadID(idController.text.trim(), imageUrl);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your identity document has been submitted for review.',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your identity document could not be submitted. Please try again.',
          ),
        ),
      );
    } finally {
      idController.dispose();

      if (mounted) {
        setState(() => _uploadingId = false);
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return;

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );

    if (image == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final extension = image.path.split('.').last.toLowerCase();

      final reference = FirebaseStorage.instance.ref(
        'profiles/$userId/'
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );

      await reference.putFile(File(image.path));
      final url = await reference.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your profile photo could not be uploaded. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.isCurrentUser,
    required this.uploadingPhoto,
    required this.onChangePhoto,
  });

  final UserModel user;
  final bool isCurrentUser;
  final bool uploadingPhoto;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName(user);

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
            top: 26,
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
            left: -48,
            bottom: -54,
            child: Container(
              width: 145,
              height: 145,
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
                74,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white24,
                          backgroundImage: user.photoUrl?.isNotEmpty == true
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl?.isNotEmpty == true
                              ? null
                              : Text(
                                  _initials(displayName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      if (isCurrentUser)
                        Positioned(
                          right: -4,
                          bottom: 2,
                          child: IconButton.filled(
                            tooltip: 'Change profile photo',
                            onPressed: uploadingPhoto ? null : onChangePhoto,
                            icon: uploadingPhoto
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt_rounded),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _HeroBadge(
                        icon: user.role == 'employer'
                            ? Icons.business_center_outlined
                            : Icons.engineering_outlined,
                        label: user.role == 'employer'
                            ? 'Employer'
                            : 'Job seeker',
                      ),
                      if (user.isVerified)
                        const _HeroBadge(
                          icon: Icons.verified_rounded,
                          label: 'Verified',
                          highlighted: true,
                        ),
                      if (user.role == 'jobseeker')
                        _HeroBadge(
                          icon: user.isAvailable
                              ? Icons.check_circle_outline_rounded
                              : Icons.pause_circle_outline_rounded,
                          label: user.isAvailable ? 'Available' : 'Unavailable',
                        ),
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.accentGold
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: highlighted ? AppTheme.accentGold : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? AppTheme.primaryGreenDark : Colors.white,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? AppTheme.primaryGreenDark : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                icon: Icons.star_rounded,
                value: user.averageRating.toStringAsFixed(1),
                label: 'Rating',
              ),
            ),
            Container(width: 1, height: 48, color: scheme.outlineVariant),
            Expanded(
              child: _ProfileMetric(
                icon: Icons.task_alt_rounded,
                value: '${user.totalJobsCompleted}',
                label: 'Jobs',
              ),
            ),
            Container(width: 1, height: 48, color: scheme.outlineVariant),
            Expanded(
              child: _ProfileMetric(
                icon: user.isVerified
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
                value: user.isVerified ? 'Verified' : 'Basic',
                label: 'Trust level',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 21),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(icon, size: 19),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.uploadingId,
    required this.onAvailabilityChanged,
    required this.onVerifyIdentity,
    required this.onOpenNotifications,
    required this.onSignOut,
  });

  final UserModel user;
  final bool uploadingId;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onVerifyIdentity;
  final VoidCallback onOpenNotifications;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final verification = _verificationVisual(user);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: const Icon(Icons.settings_outlined, size: 19),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Account controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (user.role == 'jobseeker')
            SwitchListTile.adaptive(
              value: user.isAvailable,
              secondary: const Icon(Icons.work_history_outlined),
              title: const Text('Available for work'),
              subtitle: const Text(
                'Let employers know you are ready to accept jobs.',
              ),
              onChanged: onAvailabilityChanged,
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: verification.color.withValues(alpha: 0.12),
              foregroundColor: verification.color,
              child: Icon(verification.icon),
            ),
            title: const Text('Verify identity'),
            subtitle: Text(verification.message),
            trailing: uploadingId
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap:
                user.isVerified ||
                    user.verificationStatus == 'pending' ||
                    uploadingId
                ? null
                : onVerifyIdentity,
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.notifications_outlined),
            ),
            title: const Text('Notifications'),
            subtitle: const Text('Control job and account alerts.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenNotifications,
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              child: const Icon(Icons.logout_rounded),
            ),
            title: Text(
              'Sign out',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: const Text('End your current Kazi session.'),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _VerificationVisual {
  const _VerificationVisual({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;
}

_VerificationVisual _verificationVisual(UserModel user) {
  if (user.isVerified) {
    return const _VerificationVisual(
      icon: Icons.verified_rounded,
      color: AppTheme.success,
      message: 'Your identity has been verified.',
    );
  }

  if (user.verificationStatus == 'pending') {
    return const _VerificationVisual(
      icon: Icons.hourglass_top_rounded,
      color: AppTheme.warning,
      message: 'Your documents are under review.',
    );
  }

  return const _VerificationVisual(
    icon: Icons.badge_outlined,
    color: AppTheme.primaryGreen,
    message: 'Submit your ID to strengthen account trust.',
  );
}

class _ProfileNavigation extends StatelessWidget {
  const _ProfileNavigation({required this.isEmployer});

  final bool isEmployer;

  @override
  Widget build(BuildContext context) {
    if (!isEmployer) {
      return Widgets.bottomNav(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/jobseeker/home');
            case 1:
              context.go('/jobseeker/applications');
            case 2:
              context.go('/jobseeker/wallet');
            case 3:
              context.go('/chat');
            case 4:
              context.go('/profile');
          }
        },
      );
    }

    return Widgets.employerBottomNav(context);
  }
}

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverAppBar(
          pinned: true,
          expandedHeight: 348,
          backgroundColor: AppTheme.primaryGreenDark,
          flexibleSpace: FlexibleSpaceBar(
            background: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreenDark,
                    AppTheme.primaryGreen,
                    AppTheme.teal,
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == 3 ? 0 : AppSpacing.md,
                ),
                child: Widgets.shimmerLoader(height: index == 0 ? 112 : 150),
              ),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStateView extends StatelessWidget {
  const _ProfileStateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Icon(icon, size: 31),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _displayName(UserModel user) {
  final name = user.name.trim();
  return name.isEmpty ? 'Kazi user' : name;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) return 'K';

  return parts.map((part) => part[0].toUpperCase()).join();
}
