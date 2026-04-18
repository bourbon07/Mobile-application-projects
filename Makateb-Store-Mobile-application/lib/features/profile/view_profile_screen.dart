import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';

/// ViewProfileScreen - View user profile screen
///
/// Equivalent to Vue's ViewProfile.vue page.
/// Displays a user's profile with information and admin editing capabilities.
///
/// Features:
/// - Loading state
/// - Back button
/// - Profile card with gradient header
/// - Avatar display
/// - User information fields
/// - Admin edit mode
/// - Private account handling
/// - Chat and block actions
/// - Dark mode support
/// - Responsive design
class ViewProfileScreen extends ConsumerStatefulWidget {
  /// User ID to view
  final String? userId;

  /// Mock user profile data
  final ViewProfileUserData? userProfile;

  /// Mock current user data
  final ViewProfileCurrentUser? currentUser;

  /// Loading state
  final bool loading;

  /// Whether in edit mode (admin only)
  final bool isEditing;

  /// Saving changes state
  final bool saving;

  /// Callback when back is tapped
  final VoidCallback? onBack;

  /// Callback when edit mode is toggled
  final void Function(bool editMode)? onEditModeChanged;

  /// Callback when changes are saved
  final void Function(ViewProfileFormData data)? onSaveChanges;

  /// Callback when chat is tapped
  final void Function(String userId)? onChat;

  /// Callback when block user is tapped
  final void Function(String userId)? onBlockUser;

  /// Labels for localization
  final ViewProfileScreenLabels? labels;

  const ViewProfileScreen({
    super.key,
    this.userId,
    this.userProfile,
    this.currentUser,
    this.loading = false,
    this.isEditing = false,
    this.saving = false,
    this.onBack,
    this.onEditModeChanged,
    this.onSaveChanges,
    this.onChat,
    this.onBlockUser,
    this.labels,
  });

  @override
  ConsumerState<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends ConsumerState<ViewProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  @override
  void didUpdateWidget(ViewProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userProfile != oldWidget.userProfile ||
        widget.isEditing != oldWidget.isEditing) {
      _initializeFormData();
    }
  }

  void _initializeFormData() {
    if (widget.userProfile != null) {
      final nameParts = _splitName(widget.userProfile!.name);
      _firstNameController.text = nameParts.first;
      _lastNameController.text = nameParts.last;
      _emailController.text = widget.userProfile!.email;
      _phoneController.text = widget.userProfile!.phone ?? '';
      _locationController.text = widget.userProfile!.location ?? '';
    }
  }

  ({String first, String last}) _splitName(String? name) {
    if (name == null || name.isEmpty) return (first: '', last: '');
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return (first: '', last: '');
    if (parts.length == 1) return (first: parts[0], last: '');
    final first = parts[0];
    final last = parts.sublist(1).join(' ');
    return (first: first, last: last);
  }

  String _getFirstName(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : '';
  }

  String _getLastName(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  String _getRoleDisplay(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'customer':
        return 'Customer';
      default:
        return role ?? '';
    }
  }

  void _handleSaveChanges() {
    widget.onSaveChanges?.call(
      ViewProfileFormData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        location: _locationController.text,
      ),
    );
  }

  void _handleCancelEdit() {
    _initializeFormData();
    widget.onEditModeChanged?.call(false);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? ViewProfileScreenLabels.forLanguage(currentLanguage);

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
                    const Color(0xFFFEF3C7), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: widget.loading
            ? Center(
                child: Text(
                  labels.loading,
                  style: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF) // gray-400
                        : const Color(0xFF4B5563), // gray-600
                  ),
                ),
              )
            : widget.userProfile == null
            ? Center(
                child: Text(
                  labels.profileNotFound,
                  style: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF4B5563),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG * 2, // px-4 sm:px-6 lg:px-8
                  vertical: AppTheme.spacingXXL * 2, // py-8
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onBack,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSM,
                              vertical: AppTheme.spacingSM,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chevron_left,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFFF59E0B) // amber-500
                                      : const Color(0xFF92400E), // amber-800
                                ),
                                const SizedBox(width: AppTheme.spacingSM),
                                Text(
                                  labels.back,
                                  style: AppTextStyles.bodyMediumStyle(
                                    color: isDark
                                        ? const Color(0xFFF59E0B) // amber-500
                                        : const Color(0xFF92400E), // amber-800
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
                      // Profile Card
                      _buildProfileCard(isDark, labels),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, ViewProfileScreenLabels labels) {
    final userProfile = widget.userProfile!;
    final isAdmin = widget.currentUser?.role == 'admin';
    final isOwnProfile = widget.currentUser?.id == userProfile.id;
    final canEdit = isAdmin && !isOwnProfile;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.3) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // p-8
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF92400E), // amber-800
                  Color(0xFF78350F), // amber-900
                ],
              ),
            ),
            child: Row(
              children: [
                // Avatar and Name
                Expanded(
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 96, // w-24
                        height: 96, // h-24
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFDE68A), // amber-200
                              Color(0xFFFCD34D), // amber-400
                            ],
                          ),
                        ),
                        child:
                            userProfile.avatarUrl != null &&
                                userProfile.avatarUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  userProfile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildDefaultAvatar(isDark),
                                ),
                              )
                            : _buildDefaultAvatar(isDark),
                      ),
                      const SizedBox(
                        width: AppTheme.spacingLG * 1.5,
                      ), // space-x-6
                      // Name and Role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.name,
                              style:
                                  AppTextStyles.titleLargeStyle(
                                    color: Colors.white,
                                    // font-weight: regular (default)
                                  ).copyWith(
                                    fontSize: 30, // text-3xl
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM), // mb-2
                            Text(
                              _getRoleDisplay(userProfile.role).toUpperCase(),
                              style: AppTextStyles.bodyMediumStyle(
                                color: const Color(0xFFFDE68A), // amber-200
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (!isOwnProfile) ...[
                  // Chat Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onChat?.call(userProfile.id),
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      child: Container(
                        padding: const EdgeInsets.all(
                          AppTheme.spacingSM,
                        ), // p-2
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), // bg-white/20
                          borderRadius: AppTheme.borderRadiusLargeValue,
                        ),
                        child: const Icon(
                          Icons.message,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM), // gap-2
                  // Block Button (admin only)
                  if (isAdmin) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onBlockUser?.call(userProfile.id),
                        borderRadius: AppTheme.borderRadiusLargeValue,
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppTheme.spacingSM,
                          ), // p-2
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.8), // red-600/80
                            borderRadius: AppTheme.borderRadiusLargeValue,
                          ),
                          child: const Icon(
                            Icons.block,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // p-8
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Edit Toggle (admin only)
                if (canEdit)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.spacingLG * 1.5,
                    ), // mb-6
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          labels.userInformation,
                          style:
                              AppTextStyles.titleMediumStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827), // gray-900
                                // font-weight: regular (default)
                              ).copyWith(
                                fontSize: 24, // text-2xl
                              ),
                        ),
                        if (!widget.isEditing)
                          WoodButton(
                            onPressed: () =>
                                widget.onEditModeChanged?.call(true),
                            size: WoodButtonSize.sm,
                            child: Text(
                              labels.editInformation,
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        else
                          Row(
                            children: [
                              WoodButton(
                                onPressed: widget.saving
                                    ? null
                                    : _handleSaveChanges,
                                size: WoodButtonSize.sm,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.save,
                                      size: 16,
                                      color: Colors.white,
                                    ), // Save icon
                                    const SizedBox(width: AppTheme.spacingSM),
                                    Text(
                                      labels.saveChanges,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: AppTheme.spacingSM,
                              ), // gap-2
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _handleCancelEdit,
                                  borderRadius: AppTheme.borderRadiusLargeValue,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingLG, // px-4
                                      vertical: AppTheme.spacingSM, // py-2
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(
                                                0xFF78350F,
                                              ) // amber-800
                                            : const Color(
                                                0xFFFDE68A,
                                              ), // amber-200
                                        width: 2,
                                      ),
                                      borderRadius:
                                          AppTheme.borderRadiusLargeValue,
                                    ),
                                    child: Text(
                                      labels.cancel,
                                      style: AppTextStyles.bodySmallStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF111827,
                                              ), // gray-900
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppTheme.spacingLG * 1.5,
                    ), // mb-6
                    child: Text(
                      labels.userInformation,
                      style:
                          AppTextStyles.titleMediumStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827), // gray-900
                            // font-weight: regular (default)
                          ).copyWith(
                            fontSize: 24, // text-2xl
                          ),
                    ),
                  ),

                // Private Account Message
                if (userProfile.isPrivate && !isAdmin)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.spacingXXL * 2,
                      ), // py-8
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 64, // w-16 h-16
                            color: isDark
                                ? const Color(0xFF6B7280) // gray-500
                                : const Color(0xFF9CA3AF), // gray-400
                          ),
                          const SizedBox(height: AppTheme.spacingLG), // mb-4
                          Text(
                            labels.privateAccount,
                            style:
                                AppTextStyles.titleSmallStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827), // gray-900
                                  fontWeight: AppTextStyles.medium,
                                ).copyWith(
                                  fontSize: 18, // text-lg
                                ),
                          ),
                          const SizedBox(height: AppTheme.spacingSM), // mb-2
                          Text(
                            labels.privateProfileMessage,
                            style: AppTextStyles.bodySmallStyle(
                              color: isDark
                                  ? const Color(0xFF9CA3AF) // gray-400
                                  : const Color(0xFF4B5563), // gray-600
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Information Grid
                  Column(
                    children: [
                      // First Name
                      _buildInfoField(
                        label: labels.firstName,
                        icon: Icons.person,
                        value: _getFirstName(userProfile.name),
                        controller: _firstNameController,
                        isEditing: widget.isEditing && canEdit,
                        isDark: isDark,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(
                        height: AppTheme.spacingLG * 1.5,
                      ), // space-y-6
                      // Last Name
                      _buildInfoField(
                        label: labels.lastName,
                        icon: Icons.person,
                        value: _getLastName(userProfile.name),
                        controller: _lastNameController,
                        isEditing: widget.isEditing && canEdit,
                        isDark: isDark,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(
                        height: AppTheme.spacingLG * 1.5,
                      ), // space-y-6
                      // Email
                      _buildInfoField(
                        label: labels.email,
                        icon: Icons.email,
                        value: userProfile.email,
                        controller: _emailController,
                        isEditing: widget.isEditing && canEdit,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(
                        height: AppTheme.spacingLG * 1.5,
                      ), // space-y-6
                      // Phone
                      _buildInfoField(
                        label: labels.phone,
                        icon: Icons.phone,
                        value: userProfile.phone ?? labels.notProvided,
                        controller: _phoneController,
                        isEditing: widget.isEditing && canEdit,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(
                        height: AppTheme.spacingLG * 1.5,
                      ), // space-y-6
                      // Location
                      _buildInfoField(
                        label: labels.location,
                        icon: Icons.location_on,
                        value: userProfile.location ?? labels.notProvided,
                        controller: _locationController,
                        isEditing: widget.isEditing && canEdit,
                        isDark: isDark,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(
                        height: AppTheme.spacingLG * 1.5,
                      ), // space-y-6
                      // Bio
                      if (userProfile.bio != null &&
                          userProfile.bio!.isNotEmpty) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labels.bio,
                              style: AppTextStyles.bodySmallStyle(
                                color: isDark
                                    ? const Color(0xFF9CA3AF) // gray-400
                                    : const Color(0xFF4B5563), // gray-600
                                fontWeight: AppTextStyles.medium,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSM), // mb-2
                            Text(
                              userProfile.bio!,
                              style: AppTextStyles.bodyMediumStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827), // gray-900
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: AppTheme.spacingLG * 1.5,
                        ), // space-y-6
                      ],
                    ],
                  ),

                // Privacy Settings
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.2,
                          ) // amber-900/20
                        : const Color(0xFFFEF3C7), // amber-50
                    borderRadius: AppTheme.borderRadiusLargeValue,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels.privacySettings,
                        style: AppTextStyles.bodyMediumStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827), // gray-900
                          // font-weight: regular (default)
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSM / 2),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmallStyle(
                            color: isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563), // gray-600
                          ),
                          children: [
                            TextSpan(text: '${labels.profileVisibility}: '),
                            TextSpan(
                              text: userProfile.isPrivate
                                  ? labels.private
                                  : labels.public,
                              style: AppTextStyles.bodySmallStyle(
                                color: isDark
                                    ? const Color(0xFF9CA3AF) // gray-400
                                    : const Color(0xFF4B5563), // gray-600
                                fontWeight: AppTextStyles.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required IconData icon,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF4B5563), // gray-600
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Text(
              label,
              style: AppTextStyles.bodySmallStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        isEditing
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: InputDecoration(
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
                ),
                style: AppTextStyles.bodyLargeStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                ),
              )
            : Text(
                value,
                style: AppTextStyles.bodyLargeStyle(
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF111827), // gray-900
                ),
              ),
      ],
    );
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Center(
      child: Icon(
        Icons.person,
        size: 48,
        color: const Color(0xFF78350F), // amber-900
      ),
    );
  }
}

/// ViewProfileUserData - User profile data model
class ViewProfileUserData {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? location;
  final String? bio;
  final String? avatarUrl;
  final String? role;
  final bool isPrivate;

  const ViewProfileUserData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
    this.bio,
    this.avatarUrl,
    this.role,
    this.isPrivate = false,
  });
}

/// ViewProfileCurrentUser - Current user data model
class ViewProfileCurrentUser {
  final String id;
  final String? role;

  const ViewProfileCurrentUser({required this.id, this.role});
}

/// ViewProfileFormData - Form data model
class ViewProfileFormData {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;

  const ViewProfileFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
  });
}

/// ViewProfileScreenLabels - Localization labels
class ViewProfileScreenLabels {
  final String loading;
  final String profileNotFound;
  final String back;
  final String userInformation;
  final String editInformation;
  final String saveChanges;
  final String cancel;
  final String privateAccount;
  final String privateProfileMessage;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String bio;
  final String privacySettings;
  final String profileVisibility;
  final String private;
  final String public;
  final String notProvided;

  const ViewProfileScreenLabels({
    required this.loading,
    required this.profileNotFound,
    required this.back,
    required this.userInformation,
    required this.editInformation,
    required this.saveChanges,
    required this.cancel,
    required this.privateAccount,
    required this.privateProfileMessage,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.bio,
    required this.privacySettings,
    required this.profileVisibility,
    required this.private,
    required this.public,
    required this.notProvided,
  });

  factory ViewProfileScreenLabels.defaultLabels() {
    return ViewProfileScreenLabels.forLanguage('en');
  }

  factory ViewProfileScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ViewProfileScreenLabels(
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      profileNotFound: isArabic
          ? 'الملف الشخصي غير موجود'
          : 'Profile not found',
      back: isArabic ? 'رجوع' : 'Back',
      userInformation: isArabic ? 'معلومات المستخدم' : 'User Information',
      editInformation: isArabic ? 'تعديل المعلومات' : 'Edit Information',
      saveChanges: isArabic ? 'حفظ التغييرات' : 'Save Changes',
      cancel: isArabic ? 'إلغاء' : 'Cancel',
      privateAccount: isArabic ? 'حساب خاص' : 'Private Account',
      privateProfileMessage: isArabic
          ? 'قام هذا المستخدم بتعيين ملفه الشخصي كخاص.'
          : 'This user has set their profile to private.',
      firstName: isArabic ? 'الاسم الأول' : 'First Name',
      lastName: isArabic ? 'اسم العائلة' : 'Last Name',
      email: isArabic ? 'البريد الإلكتروني' : 'Email',
      phone: isArabic ? 'الهاتف' : 'Phone',
      location: isArabic ? 'الموقع' : 'Location',
      bio: isArabic ? 'السيرة الذاتية' : 'Bio',
      privacySettings: isArabic ? 'إعدادات الخصوصية' : 'Privacy Settings',
      profileVisibility: isArabic ? 'رؤية الملف الشخصي' : 'Profile Visibility',
      private: isArabic ? 'خاص' : 'Private',
      public: isArabic ? 'عام' : 'Public',
      notProvided: isArabic ? 'غير متوفر' : 'Not provided',
    );
  }
}


