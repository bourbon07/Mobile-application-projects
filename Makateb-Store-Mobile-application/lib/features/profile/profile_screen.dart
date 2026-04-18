import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/image_upload.dart';
import '../../core/stores/language_store.dart';

/// ProfileScreen - User profile screen
///
/// Equivalent to Vue's Profile.vue page.
/// Displays user profile information with edit functionality.
///
/// Features:
/// - Login prompt if no user
/// - Profile image with ImageUpload
/// - User name and email
/// - Bio textarea
/// - Phone number field
/// - Location field
/// - Private account checkbox
/// - Edit/Save/Cancel buttons
/// - Dark mode support
/// - Responsive design
class ProfileScreen extends ConsumerStatefulWidget {
  /// Mock user data (null for guest)
  final ProfileUserData? user;

  /// Mock profile data
  final ProfileData? profile;

  /// Whether in edit mode
  final bool editMode;

  /// Saving state
  final bool saving;

  /// Callback when sign in is tapped
  final VoidCallback? onSignIn;

  /// Callback when edit mode is toggled
  final void Function(bool editMode)? onEditModeChanged;

  /// Callback when avatar is updated
  final Future<void> Function(String imageUrl)? onAvatarUpdate;

  /// Callback when profile is saved
  final Future<void> Function(ProfileFormData data)? onSave;

  /// Callback when edit is cancelled
  final VoidCallback? onCancel;

  /// Fetch Cloudinary images (List of URLs)
  final Future<List<String>> Function()? onFetchCloudinaryImages;

  /// Upload to Cloudinary using a source (URL or binary) and return uploaded URL
  final Future<String?> Function({
    String? source,
    Uint8List? fileBytes,
    String? fileName,
  })?
  onUploadToCloudinary;

  /// Labels for localization
  final ProfileScreenLabels? labels;

  const ProfileScreen({
    super.key,
    this.user,
    this.profile,
    this.editMode = false,
    this.saving = false,
    this.onSignIn,
    this.onEditModeChanged,
    this.onAvatarUpdate,
    this.onSave,
    this.onCancel,
    this.onFetchCloudinaryImages,
    this.onUploadToCloudinary,
    this.labels,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ProfileFormData _formData;
  String? _avatarUrl;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  bool _editModeLocal = false;
  bool _savingLocal = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _initializeFormData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile ||
        widget.editMode != oldWidget.editMode) {
      _initializeFormData();
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    _formData = ProfileFormData(
      bio: widget.profile?.bio ?? widget.user?.bio ?? '',
      phone: widget.profile?.phone ?? widget.user?.phone ?? '',
      location: widget.profile?.location ?? widget.user?.location ?? '',
      isPrivate: widget.profile?.isPrivate ?? false,
    );
    _avatarUrl = widget.profile?.avatarUrl ?? widget.user?.avatarUrl;

    // Keep controllers in sync (prevents cursor jump / value reset on rebuild).
    _bioController.text = _formData.bio;
    _phoneController.text = _formData.phone;
    _locationController.text = _formData.location;

    // If parent doesn't control edit/saving, manage them locally.
    if (widget.onEditModeChanged == null) _editModeLocal = widget.editMode;
    if (widget.onSave == null) _savingLocal = widget.saving;
  }

  String _getUserFullName() {
    if (widget.user?.name != null) {
      return widget.user!.name!;
    }
    if (widget.user?.firstName != null || widget.user?.lastName != null) {
      return '${widget.user?.firstName ?? ''} ${widget.user?.lastName ?? ''}'
          .trim();
    }
    return 'User';
  }

  String _getUserInitials() {
    final name = _getUserFullName();
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Future<void> _handleAvatarUpdate(List<String> images) async {
    if (images.isNotEmpty) {
      setState(() {
        _avatarUrl = images.first;
      });
      if (widget.onAvatarUpdate != null) {
        await widget.onAvatarUpdate!(images.first);
      }
    } else {
      // Clear avatar
      setState(() {
        _avatarUrl = null;
      });
      if (widget.onAvatarUpdate != null) {
        await widget.onAvatarUpdate!('');
      }
    }
  }

  Future<void> _handleCloudinaryUploadSource({
    String? source,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    if (widget.onUploadToCloudinary == null) return;
    final uploaded = await widget.onUploadToCloudinary!.call(
      source: source,
      fileBytes: fileBytes,
      fileName: fileName,
    );
    if (uploaded == null || uploaded.trim().isEmpty) return;
    await _handleAvatarUpdate([uploaded.trim()]);
  }

  bool get _isEditMode =>
      widget.onEditModeChanged != null ? widget.editMode : _editModeLocal;
  bool get _isSaving => widget.onSave != null ? widget.saving : _savingLocal;

  Future<void> _handleSave() async {
    if (widget.onSave == null) return;
    if (_isSaving) return;
    setState(() => _savingLocal = true);
    try {
      await widget.onSave!(_formData);
      if (widget.onEditModeChanged != null) {
        widget.onEditModeChanged!.call(false);
      } else {
        setState(() => _editModeLocal = false);
      }
    } finally {
      if (mounted) setState(() => _savingLocal = false);
    }
  }

  void _handleCancel() {
    _initializeFormData();
    widget.onCancel?.call();
  }

  void _toggleEditMode() {
    if (widget.onEditModeChanged != null) {
      widget.onEditModeChanged!.call(!widget.editMode);
    } else {
      setState(() => _editModeLocal = !_editModeLocal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? ProfileScreenLabels.forLanguage(currentLanguage);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // No user - show login prompt
    if (widget.user == null) {
      return PageLayout(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF111827), // gray-900
                      const Color(0xFF1F2937), // gray-800
                    ]
                  : [
                      const Color(0xFFFFFBEB), // amber-50
                      Colors.white,
                    ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  labels.pleaseLoginToViewProfile,
                  style:
                      AppTextStyles.titleLargeStyle(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF111827), // gray-900
                        fontWeight: FontWeight.bold, // font-bold
                      ).copyWith(
                        fontSize: 30, // text-3xl
                      ),
                ),
                const SizedBox(height: AppTheme.spacingLG), // mb-4
                WoodButton(
                  onPressed: widget.onSignIn,
                  child: Text(
                    labels.signIn,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User logged in - show profile
    return PageLayout(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF111827), // gray-900
                    const Color(0xFF1F2937), // gray-800
                  ]
                : [
                    const Color(0xFFFFFBEB), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLG * 2, // px-4 sm:px-6 lg:px-8
            vertical: AppTheme.spacingXXL * 2, // py-8
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    labels.myProfile,
                    style:
                        AppTextStyles.titleLargeStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827), // gray-900
                          fontWeight: FontWeight.bold, // font-bold
                        ).copyWith(
                          fontSize: 36, // text-4xl
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
                  // Profile Card
                  Container(
                    padding: const EdgeInsets.all(
                      AppTheme.spacingXXL * 2,
                    ), // p-8
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937) // gray-800
                          : Colors.white,
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF78350F).withAlpha(
                                77,
                              ) // amber-900/30
                            : const Color(0xFFFEF3C7), // amber-100
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(
                            20,
                          ), // closer to shadow-md
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Image Section
                        Column(
                          children: [
                            // Avatar
                            Container(
                              width: 128, // w-32
                              height: 128, // h-32
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF92400E) // amber-700
                                      : const Color(0xFFFCD34D), // amber-300
                                  width: 4,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        _avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildInitialsAvatar(isDark),
                                      )
                                    : _buildInitialsAvatar(isDark),
                              ),
                            ),

                            // ImageUpload
                            const SizedBox(height: AppTheme.spacingLG), // mt-4
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 448,
                              ), // max-w-md
                              child: ImageUpload(
                                images: _avatarUrl != null
                                    ? [_avatarUrl!]
                                    : null,
                                multiple: false,
                                showCloudinary: true,
                                onImagesChanged: _handleAvatarUpdate,
                                onFetchCloudinaryImages:
                                    widget.onFetchCloudinaryImages,
                                onFileSelected: ({filePath, fileBytes, fileName}) {
                                  // ImageUpload is UI-only; we upload via backend and then set avatar.
                                  _handleCloudinaryUploadSource(
                                    source: filePath,
                                    fileBytes: fileBytes,
                                    fileName: fileName,
                                  );
                                },
                              ),
                            ),

                            // Name
                            const SizedBox(height: AppTheme.spacingLG), // mt-4
                            Text(
                              _getUserFullName(),
                              style:
                                  AppTextStyles.titleMediumStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827), // gray-900
                                    fontWeight: FontWeight.bold, // font-bold
                                  ).copyWith(
                                    fontSize: 24, // text-2xl
                                  ),
                            ),

                            // Email
                            Text(
                              widget.user?.email ?? '',
                              style: AppTextStyles.bodyMediumStyle(
                                color: isDark
                                    ? const Color(0xFF9CA3AF) // gray-400
                                    : const Color(0xFF4B5563), // gray-600
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacingXXL * 2), // mb-8
                        // Profile Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bio
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labels.bio,
                                  style: AppTextStyles.bodyMediumStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827), // gray-900
                                    fontWeight:
                                        FontWeight.w600, // font-semibold
                                  ),
                                ),
                                const SizedBox(
                                  height: AppTheme.spacingSM,
                                ), // mb-2
                                _isEditMode
                                    ? TextField(
                                        maxLines: 3,
                                        controller: _bioController,
                                        onChanged: (value) {
                                          setState(() {
                                            _formData = _formData.copyWith(
                                              bio: value,
                                            );
                                          });
                                        },
                                        decoration: InputDecoration(
                                          hintText: labels.tellUsAboutYourself,
                                          filled: true,
                                          fillColor: isDark
                                              ? const Color(
                                                  0xFF374151,
                                                ) // gray-700
                                              : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                AppTheme.borderRadiusLargeValue,
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? const Color(
                                                      0xFF78350F,
                                                    ) // amber-800
                                                  : const Color(
                                                      0xFFFDE68A,
                                                    ), // amber-200
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                AppTheme.borderRadiusLargeValue,
                                            borderSide: BorderSide(
                                              color: isDark
                                                  ? const Color(
                                                      0xFF78350F,
                                                    ) // amber-800
                                                  : const Color(
                                                      0xFFFDE68A,
                                                    ), // amber-200
                                              width: 2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                AppTheme.borderRadiusLargeValue,
                                            borderSide: BorderSide(
                                              color: const Color(
                                                0xFFF59E0B,
                                              ), // amber-500
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.all(
                                            AppTheme.spacingLG,
                                          ), // px-4 py-2
                                          hintStyle:
                                              AppTextStyles.bodyMediumStyle(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF6B7280,
                                                      ) // gray-500
                                                    : const Color(
                                                        0xFF9CA3AF,
                                                      ), // gray-400
                                              ),
                                        ),
                                        style: AppTextStyles.bodyMediumStyle(
                                          color: isDark
                                              ? Colors.white
                                              : const Color(
                                                  0xFF111827,
                                                ), // gray-900
                                        ),
                                      )
                                    : Text(
                                        _formData.bio.isNotEmpty
                                            ? _formData.bio
                                            : labels.noBioAdded,
                                        style: AppTextStyles.bodyMediumStyle(
                                          color: isDark
                                              ? const Color(
                                                  0xFFD1D5DB,
                                                ) // gray-300
                                              : const Color(
                                                  0xFF374151,
                                                ), // gray-700
                                        ),
                                      ),
                              ],
                            ),

                            const SizedBox(
                              height: AppTheme.spacingLG * 1.5,
                            ), // space-y-6
                            // Phone and Location Grid
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth >= 640) {
                                  // Desktop: 2 columns
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildPhoneField(
                                          isDark,
                                          labels,
                                          isRTL,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppTheme.spacingLG * 1.5,
                                      ), // gap-6
                                      Expanded(
                                        child: _buildLocationField(
                                          isDark,
                                          labels,
                                          isRTL,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Mobile: Stacked
                                  return Column(
                                    children: [
                                      _buildPhoneField(isDark, labels, isRTL),
                                      const SizedBox(
                                        height: AppTheme.spacingLG * 1.5,
                                      ), // gap-6
                                      _buildLocationField(
                                        isDark,
                                        labels,
                                        isRTL,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),

                            const SizedBox(
                              height: AppTheme.spacingLG * 1.5,
                            ), // space-y-6
                            // Private Account Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _formData.isPrivate,
                                  onChanged: _isEditMode
                                      ? (value) {
                                          setState(() {
                                            _formData = _formData.copyWith(
                                              isPrivate: value ?? false,
                                            );
                                          });
                                        }
                                      : null,
                                  activeColor: const Color(
                                    0xFFF59E0B,
                                  ), // amber-500
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: isRTL
                                            ? [
                                                Text(
                                                  labels.privateAccount,
                                                  style:
                                                      AppTextStyles.bodyMediumStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF111827,
                                                              ), // gray-900
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(
                                                  width: AppTheme.spacingSM,
                                                ),
                                                Icon(
                                                  _formData.isPrivate
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF111827,
                                                        ), // gray-900
                                                ),
                                              ]
                                            : [
                                                Icon(
                                                  _formData.isPrivate
                                                      ? Icons.lock
                                                      : Icons.lock_open,
                                                  size: 16,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF111827,
                                                        ), // gray-900
                                                ),
                                                const SizedBox(
                                                  width: AppTheme.spacingSM,
                                                ),
                                                Text(
                                                  labels.privateAccount,
                                                  style:
                                                      AppTextStyles.bodyMediumStyle(
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF111827,
                                                              ), // gray-900
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingSM / 2,
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              start: 32,
                                            ), // ml-8 (RTL-safe)
                                        child: Text(
                                          labels.privateAccountDescription,
                                          style: AppTextStyles.bodySmallStyle(
                                            color: isDark
                                                ? const Color(
                                                    0xFF9CA3AF,
                                                  ) // gray-400
                                                : const Color(
                                                    0xFF4B5563,
                                                  ), // gray-600
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppTheme.spacingLG), // pt-4
                            // Action Buttons
                            _isEditMode
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: WoodButton(
                                          onPressed: _isSaving
                                              ? null
                                              : _handleSave,
                                          child: Text(
                                            _isSaving
                                                ? labels.saving
                                                : labels.saveChanges,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: AppTheme.spacingLG,
                                      ), // gap-4
                                      Expanded(
                                        child: WoodButton(
                                          onPressed: _handleCancel,
                                          variant: WoodButtonVariant.outline,
                                          child: Text(labels.cancel),
                                        ),
                                      ),
                                    ],
                                  )
                                : SizedBox(
                                    width: double.infinity, // w-full
                                    child: WoodButton(
                                      onPressed: _toggleEditMode,
                                      child: Text(
                                        labels.editProfile,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF78350F) // amber-800
            : const Color(0xFFFDE68A), // amber-200
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? const Color(0xFF92400E) // amber-700
              : const Color(0xFFFCD34D), // amber-300
          width: 4,
        ),
      ),
      child: Center(
        child: Text(
          _getUserInitials(),
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? const Color(0xFFFEF3C7) // amber-100
                    : const Color(0xFF78350F), // amber-900
                fontWeight: FontWeight.bold, // font-bold
              ).copyWith(
                fontSize: 36, // text-4xl
              ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDark, ProfileScreenLabels labels, bool isRTL) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: isRTL
              ? [
                  Text(
                    labels.phoneNumber,
                    style: AppTextStyles.bodyMediumStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.w600, // font-semibold
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                  ),
                ]
              : [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    labels.phoneNumber,
                    style: AppTextStyles.bodyMediumStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.w600, // font-semibold
                    ),
                  ),
                ],
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        _isEditMode
            ? TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    _formData = _formData.copyWith(phone: value);
                  });
                },
                decoration: InputDecoration(
                  hintText: labels.phonePlaceholder,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF374151) // gray-700
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF78350F) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF78350F) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: const Color(0xFFF59E0B), // amber-500
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(
                    AppTheme.spacingLG,
                  ), // px-4 py-2
                  hintStyle: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF6B7280) // gray-500
                        : const Color(0xFF9CA3AF), // gray-400
                  ),
                ),
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                ),
              )
            : Text(
                _formData.phone.isNotEmpty
                    ? _formData.phone
                    : labels.noPhoneAdded,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFFD1D5DB) // gray-300
                      : const Color(0xFF374151), // gray-700
                ),
              ),
      ],
    );
  }

  Widget _buildLocationField(
    bool isDark,
    ProfileScreenLabels labels,
    bool isRTL,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: isRTL
              ? [
                  Text(
                    labels.location,
                    style: AppTextStyles.bodyMediumStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.w600, // font-semibold
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                  ),
                ]
              : [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    labels.location,
                    style: AppTextStyles.bodyMediumStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.w600, // font-semibold
                    ),
                  ),
                ],
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        _isEditMode
            ? TextField(
                controller: _locationController,
                onChanged: (value) {
                  setState(() {
                    _formData = _formData.copyWith(location: value);
                  });
                },
                decoration: InputDecoration(
                  hintText: labels.locationPlaceholder,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF374151) // gray-700
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF78350F) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF78350F) // amber-800
                          : const Color(0xFFFDE68A), // amber-200
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(
                      color: const Color(0xFFF59E0B), // amber-500
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(
                    AppTheme.spacingLG,
                  ), // px-4 py-2
                  hintStyle: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF6B7280) // gray-500
                        : const Color(0xFF9CA3AF), // gray-400
                  ),
                ),
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                ),
              )
            : Text(
                _formData.location.isNotEmpty
                    ? _formData.location
                    : labels.noLocationAdded,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFFD1D5DB) // gray-300
                      : const Color(0xFF374151), // gray-700
                ),
              ),
      ],
    );
  }
}

/// ProfileUserData - User data model
class ProfileUserData {
  final String id;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? bio;
  final String? phone;
  final String? location;
  final String? avatarUrl;

  const ProfileUserData({
    required this.id,
    this.name,
    this.firstName,
    this.lastName,
    required this.email,
    this.bio,
    this.phone,
    this.location,
    this.avatarUrl,
  });
}

/// ProfileData - Profile data model
class ProfileData {
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? location;
  final bool isPrivate;

  const ProfileData({
    this.avatarUrl,
    this.bio,
    this.phone,
    this.location,
    this.isPrivate = false,
  });
}

/// ProfileFormData - Form data model
class ProfileFormData {
  final String bio;
  final String phone;
  final String location;
  final bool isPrivate;

  const ProfileFormData({
    this.bio = '',
    this.phone = '',
    this.location = '',
    this.isPrivate = false,
  });

  ProfileFormData copyWith({
    String? bio,
    String? phone,
    String? location,
    bool? isPrivate,
  }) {
    return ProfileFormData(
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

/// ProfileScreenLabels - Localization labels
class ProfileScreenLabels {
  final String pleaseLoginToViewProfile;
  final String signIn;
  final String myProfile;
  final String bio;
  final String tellUsAboutYourself;
  final String noBioAdded;
  final String phoneNumber;
  final String phonePlaceholder;
  final String noPhoneAdded;
  final String location;
  final String locationPlaceholder;
  final String noLocationAdded;
  final String privateAccount;
  final String privateAccountDescription;
  final String saving;
  final String saveChanges;
  final String cancel;
  final String editProfile;

  const ProfileScreenLabels({
    required this.pleaseLoginToViewProfile,
    required this.signIn,
    required this.myProfile,
    required this.bio,
    required this.tellUsAboutYourself,
    required this.noBioAdded,
    required this.phoneNumber,
    required this.phonePlaceholder,
    required this.noPhoneAdded,
    required this.location,
    required this.locationPlaceholder,
    required this.noLocationAdded,
    required this.privateAccount,
    required this.privateAccountDescription,
    required this.saving,
    required this.saveChanges,
    required this.cancel,
    required this.editProfile,
  });

  factory ProfileScreenLabels.defaultLabels() {
    return ProfileScreenLabels.forLanguage('en');
  }

  factory ProfileScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ProfileScreenLabels(
      pleaseLoginToViewProfile: isArabic
          ? 'يرجى تسجيل الدخول لعرض ملفك الشخصي'
          : 'Please login to view your profile',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      myProfile: isArabic ? 'ملفي الشخصي' : 'My Profile',
      bio: isArabic ? 'السيرة الذاتية' : 'Bio',
      tellUsAboutYourself: isArabic
          ? 'أخبرنا عن نفسك...'
          : 'Tell us about yourself...',
      noBioAdded: isArabic ? 'لم تتم إضافة سيرة ذاتية' : 'No bio added',
      phoneNumber: isArabic ? 'رقم الهاتف' : 'Phone Number',
      phonePlaceholder: isArabic ? 'أدخل رقم هاتفك' : 'Enter your phone number',
      noPhoneAdded: isArabic ? 'لم يتم إضافة رقم هاتف' : 'No phone added',
      location: isArabic ? 'الموقع' : 'Location',
      locationPlaceholder: isArabic ? 'أدخل موقعك' : 'Enter your location',
      noLocationAdded: isArabic ? 'لم يتم إضافة موقع' : 'No location added',
      privateAccount: isArabic ? 'حساب خاص' : 'Private Account',
      privateAccountDescription: isArabic
          ? 'عند التفعيل، سيتم إخفاء ملفك الشخصي عن المستخدمين الآخرين'
          : 'When enabled, your profile will be hidden from other users',
      saving: isArabic ? 'جاري الحفظ...' : 'Saving...',
      saveChanges: isArabic ? 'حفظ التغييرات' : 'Save Changes',
      cancel: isArabic ? 'إلغاء' : 'Cancel',
      editProfile: isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile',
    );
  }
}
