import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/storage_service.dart';

/// SettingsScreen - User settings screen
///
/// Equivalent to Vue's Settings.vue page.
/// Displays user settings with forms for personal info, password change, language, and account deletion.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Mock user data (null for guest)
  final SettingsUserData? user;

  /// Mock settings data
  final SettingsData? settings;

  /// Saving personal info state
  final bool savingPersonalInfo;

  /// Changing password state
  final bool changingPassword;

  /// Current selected language
  final String selectedLanguage;

  /// Callback when sign in is tapped
  final VoidCallback? onSignIn;

  /// Callback when personal info is saved
  final Future<void> Function(SettingsPersonalInfo data)? onSavePersonalInfo;

  /// Callback when password is changed
  final Future<void> Function(SettingsPasswordForm data)? onChangePassword;

  /// Callback when language is changed
  final void Function(String language)? onLanguageChanged;

  /// Callback when delete account is confirmed
  final Future<void> Function()? onDeleteAccount;

  /// Labels for localization
  final SettingsScreenLabels? labels;

  const SettingsScreen({
    super.key,
    this.user,
    this.settings,
    this.savingPersonalInfo = false,
    this.changingPassword = false,
    this.selectedLanguage = 'en',
    this.onSignIn,
    this.onSavePersonalInfo,
    this.onChangePassword,
    this.onLanguageChanged,
    this.onDeleteAccount,
    this.labels,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _showDeleteConfirm = false;
  String _selectedLanguage = 'en';
  bool _savingPersonalInfo = false;
  bool _changingPassword = false;
  bool _savingPaymentMethod = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _initializeFormData();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != oldWidget.settings ||
        widget.user != oldWidget.user) {
      _initializeFormData();
    }
    if (widget.selectedLanguage != oldWidget.selectedLanguage) {
      _selectedLanguage = widget.selectedLanguage;
    }
  }

  void _initializeFormData() {
    if (widget.user != null) {
      final nameParts = _splitName(widget.user!.name);
      _firstNameController.text = nameParts.first;
      _lastNameController.text = nameParts.last;
      _emailController.text = widget.user!.email;
    } else if (widget.settings != null) {
      _firstNameController.text = widget.settings!.firstName;
      _lastNameController.text = widget.settings!.lastName;
      _emailController.text = widget.settings!.email;
    }
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    final storage = StorageService.instance;
    final cardNumber = storage.getString('payment_card_number') ?? '';
    final expiryDate = storage.getString('payment_expiry_date') ?? '';
    final cvv = storage.getString('payment_cvv') ?? '';

    if (mounted) {
      setState(() {
        _cardNumberController.text = cardNumber;
        _expiryDateController.text = expiryDate;
        _cvvController.text = cvv;
      });
    }
  }

  Future<void> _handleSavePaymentMethod() async {
    setState(() {
      _savingPaymentMethod = true;
    });
    try {
      final storage = StorageService.instance;
      await storage.setString(
        'payment_card_number',
        _cardNumberController.text.trim(),
      );
      await storage.setString(
        'payment_expiry_date',
        _expiryDateController.text.trim(),
      );
      await storage.setString('payment_cvv', _cvvController.text.trim());
      await storage.setString('default_payment_method', 'credit_card');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('basic_information_updated_successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingPaymentMethod = false;
        });
      }
    }
  }

  ({String first, String last}) _splitName(String? name) {
    if (name == null || name.isEmpty) return (first: '', last: '');
    final parts = name.trim().split(' ');
    if (parts.length == 1) return (first: parts[0], last: '');
    final last = parts.removeLast();
    final first = parts.join(' ');
    return (first: first, last: last);
  }

  Future<void> _handleSavePersonalInfo() async {
    if (_personalInfoFormKey.currentState?.validate() ?? false) {
      setState(() {
        _savingPersonalInfo = true;
      });
      try {
        await widget.onSavePersonalInfo?.call(
          SettingsPersonalInfo(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
          ),
        );
      } finally {
        if (mounted) setState(() => _savingPersonalInfo = false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      setState(() => _changingPassword = true);
      try {
        await widget.onChangePassword?.call(
          SettingsPasswordForm(
            currentPassword: _currentPasswordController.text,
            password: _newPasswordController.text,
            passwordConfirmation: _confirmPasswordController.text,
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } finally {
        if (mounted) setState(() => _changingPassword = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? SettingsScreenLabels.forLanguage(currentLanguage);

    if (widget.user == null) {
      return PageLayout(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labels.pleaseLoginToAccessSettings,
                style: AppTextStyles.titleLargeStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
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
      );
    }

    return PageLayout(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF1F2937)]
                : [const Color(0xFFFEF3C7), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels.settings,
                style: AppTextStyles.titleLargeStyle(
                  color: isDark ? Colors.white : Colors.black,
                ).copyWith(fontSize: 36),
              ),
              const SizedBox(height: 32),
              _buildBasicInformationSection(isDark, labels),
              const SizedBox(height: 24),
              _buildChangePasswordSection(isDark, labels),
              const SizedBox(height: 24),
              _buildLanguageSection(isDark, labels),
              const SizedBox(height: 24),
              _buildPaymentMethodSection(isDark, labels),
              const SizedBox(height: 24),
              _buildDeleteAccountSection(isDark, labels),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection(
    bool isDark,
    SettingsScreenLabels labels,
  ) {
    return _buildSection(
      isDark: isDark,
      title: labels.basicInformation,
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _firstNameController,
              label: labels.firstName,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: labels.lastName,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: labels.emailAddress,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            WoodButton(
              onPressed: _savingPersonalInfo ? null : _handleSavePersonalInfo,
              child: Text(
                _savingPersonalInfo ? labels.saving : labels.saveChanges,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSection(bool isDark, SettingsScreenLabels labels) {
    return _buildSection(
      isDark: isDark,
      title: labels.changePassword,
      child: Form(
        key: _passwordFormKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _currentPasswordController,
              label: labels.currentPassword,
              isDark: isDark,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              label: labels.newPassword,
              isDark: isDark,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              label: labels.confirmPassword,
              isDark: isDark,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            WoodButton(
              onPressed: _changingPassword ? null : _handleChangePassword,
              child: Text(
                _changingPassword ? labels.changing : labels.changePassword,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(bool isDark, SettingsScreenLabels labels) {
    return _buildSection(
      isDark: isDark,
      title: labels.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.selectLanguage,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            items: [
              DropdownMenuItem(value: 'ar', child: Text(labels.arabic)),
              DropdownMenuItem(value: 'en', child: Text(labels.english)),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedLanguage = v);
                widget.onLanguageChanged?.call(v);
              }
            },
            decoration: _inputDecoration(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(bool isDark, SettingsScreenLabels labels) {
    return _buildSection(
      isDark: isDark,
      title: labels.paymentMethod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.creditCard,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cardNumberController,
            label: labels.cardNumber,
            isDark: isDark,
            hintText: '1234 5678 9012 3456',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expiryDateController,
                  label: labels.expiryDate,
                  isDark: isDark,
                  hintText: 'MM/YY',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cvvController,
                  label: labels.cvv,
                  isDark: isDark,
                  hintText: '123',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          WoodButton(
            onPressed: _savingPaymentMethod ? null : _handleSavePaymentMethod,
            child: Text(
              _savingPaymentMethod ? labels.saving : labels.saveChanges,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountSection(bool isDark, SettingsScreenLabels labels) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.dangerZone,
            style: AppTextStyles.titleMediumStyle(
              color: Colors.red,
            ).copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            labels.deleteAccountWarning,
            style: AppTextStyles.bodyMediumStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_showDeleteConfirm) ...[
            Text(
              labels.areYouSure,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onDeleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(labels.yesDelete),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: WoodButton(
                    onPressed: () => setState(() => _showDeleteConfirm = false),
                    child: Text(
                      labels.cancel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            ElevatedButton(
              onPressed: () => setState(() => _showDeleteConfirm = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(labels.deleteAccount),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.amber.withOpacity(0.2) : Colors.amber.shade100,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMediumStyle(
              color: isDark ? Colors.white : Colors.black,
            ).copyWith(fontSize: 24),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: _inputDecoration(isDark).copyWith(hintText: hintText),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF374151) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.amber.shade900 : Colors.amber.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.amber.shade900 : Colors.amber.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
    );
  }
}

class SettingsUserData {
  final String id;
  final String? name;
  final String email;
  const SettingsUserData({required this.id, this.name, required this.email});
}

class SettingsData {
  final String firstName;
  final String lastName;
  final String email;
  const SettingsData({
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class SettingsPersonalInfo {
  final String firstName;
  final String lastName;
  final String email;
  const SettingsPersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class SettingsPasswordForm {
  final String currentPassword;
  final String password;
  final String passwordConfirmation;
  const SettingsPasswordForm({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });
}

class SettingsScreenLabels {
  final String pleaseLoginToAccessSettings;
  final String signIn;
  final String settings;
  final String basicInformation;
  final String firstName;
  final String lastName;
  final String emailAddress;
  final String saving;
  final String saveChanges;
  final String changePassword;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final String changing;
  final String language;
  final String selectLanguage;
  final String arabic;
  final String english;
  final String dangerZone;
  final String deleteAccountWarning;
  final String areYouSure;
  final String yesDelete;
  final String cancel;
  final String deleteAccount;
  final String firstNameRequired;
  final String lastNameRequired;
  final String emailRequired;
  final String invalidEmail;
  final String currentPasswordRequired;
  final String newPasswordRequired;
  final String confirmPasswordRequired;
  final String passwordsDoNotMatch;
  final String passwordMinLength;
  final String paymentMethod;
  final String creditCard;
  final String cardNumber;
  final String expiryDate;
  final String cvv;

  const SettingsScreenLabels({
    required this.pleaseLoginToAccessSettings,
    required this.signIn,
    required this.settings,
    required this.basicInformation,
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.saving,
    required this.saveChanges,
    required this.changePassword,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.changing,
    required this.language,
    required this.selectLanguage,
    required this.arabic,
    required this.english,
    required this.dangerZone,
    required this.deleteAccountWarning,
    required this.areYouSure,
    required this.yesDelete,
    required this.cancel,
    required this.deleteAccount,
    required this.firstNameRequired,
    required this.lastNameRequired,
    required this.emailRequired,
    required this.invalidEmail,
    required this.currentPasswordRequired,
    required this.newPasswordRequired,
    required this.confirmPasswordRequired,
    required this.passwordsDoNotMatch,
    required this.passwordMinLength,
    required this.paymentMethod,
    required this.creditCard,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
  });

  factory SettingsScreenLabels.forLanguage(String language) {
    final isAr = language == 'ar';
    return SettingsScreenLabels(
      pleaseLoginToAccessSettings: isAr
          ? 'يرجى تسجيل الدخول للوصول إلى الإعدادات'
          : 'Please login to access settings',
      signIn: isAr ? 'تسجيل الدخول' : 'Sign In',
      settings: isAr ? 'الإعدادات' : 'Settings',
      basicInformation: isAr ? 'المعلومات الأساسية' : 'Basic Information',
      firstName: isAr ? 'الاسم الأول' : 'First Name',
      lastName: isAr ? 'اسم العائلة' : 'Last Name',
      emailAddress: isAr ? 'البريد الإلكتروني' : 'Email Address',
      saving: isAr ? 'جاري الحفظ...' : 'Saving...',
      saveChanges: isAr ? 'حفظ التغييرات' : 'Save Changes',
      changePassword: isAr ? 'تغيير كلمة المرور' : 'Change Password',
      currentPassword: isAr ? 'كلمة المرور الحالية' : 'Current Password',
      newPassword: isAr ? 'كلمة المرور الجديدة' : 'New Password',
      confirmPassword: isAr ? 'تأكيد كلمة المرور' : 'Confirm Password',
      changing: isAr ? 'جاري التغيير...' : 'Changing...',
      language: isAr ? 'اللغة' : 'Language',
      selectLanguage: isAr ? 'اختر اللغة' : 'Select Language',
      arabic: isAr ? 'العربية' : 'Arabic',
      english: isAr ? 'الإنجليزية' : 'English',
      dangerZone: isAr ? 'منطقة الخطر' : 'Danger Zone',
      deleteAccountWarning: isAr
          ? 'حذف الحساب نهائي ولا يمكن التراجع عنه'
          : 'Deleting account is permanent and cannot be undone',
      areYouSure: isAr ? 'هل أنت متأكد؟' : 'Are you sure?',
      yesDelete: isAr ? 'نعم، احذف' : 'Yes, Delete',
      cancel: isAr ? 'إلغاء' : 'Cancel',
      deleteAccount: isAr ? 'حذف الحساب' : 'Delete Account',
      firstNameRequired: isAr ? 'الاسم الأول مطلوب' : 'First name required',
      lastNameRequired: isAr ? 'اسم العائلة مطلوب' : 'Last name required',
      emailRequired: isAr ? 'البريد الإلكتروني مطلوب' : 'Email required',
      invalidEmail: isAr ? 'بريد إلكتروني غير صالح' : 'Invalid email',
      currentPasswordRequired: isAr
          ? 'كلمة المرور الحالية مطلوبة'
          : 'Current password required',
      newPasswordRequired: isAr
          ? 'كلمة المرور الجديدة مطلوبة'
          : 'New password required',
      confirmPasswordRequired: isAr
          ? 'تأكيد كلمة المرور مطلوب'
          : 'Confirm password required',
      passwordsDoNotMatch: isAr
          ? 'كلمات المرور غير متطابقة'
          : 'Passwords do not match',
      passwordMinLength: isAr ? 'كلمة المرور قصيرة جداً' : 'Password too short',
      paymentMethod: isAr ? 'طريقة الدفع' : 'Payment Method',
      creditCard: isAr ? 'بطاقة الائتمان' : 'Credit Card',
      cardNumber: isAr ? 'رقم البطاقة' : 'Card Number',
      expiryDate: isAr ? 'تاريخ الانتهاء' : 'Expiry Date',
      cvv: isAr ? 'رمز الأمان' : 'CVV',
    );
  }
}
