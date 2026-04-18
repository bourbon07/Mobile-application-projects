import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';

/// LoginScreen - Login and registration screen
///
/// Equivalent to Vue's Login.vue page.
/// Displays a centered modal with login and registration forms.
///
/// Features:
/// - Toggle between login and register forms
/// - Email and password fields with icons
/// - Password visibility toggle
/// - Form validation
/// - Error message display
/// - Dark mode support
/// - Responsive design
class LoginScreen extends ConsumerStatefulWidget {
  /// Loading state
  final bool loading;

  /// Error message to display
  final String? error;

  /// Callback when login form is submitted
  final void Function(String email, String password)? onLogin;

  /// Callback when register form is submitted
  final void Function(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  )?
  onRegister;

  /// Callback when close button is tapped
  final VoidCallback? onClose;

  /// Callback when continue as guest is tapped
  final VoidCallback? onContinueAsGuest;

  /// Labels for localization
  final LoginScreenLabels? labels;

  const LoginScreen({
    super.key,
    this.loading = false,
    this.error,
    this.onLogin,
    this.onRegister,
    this.onClose,
    this.onContinueAsGuest,
    this.labels,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmationController = TextEditingController();

  bool _isLogin = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_loginFormKey.currentState!.validate()) {
      widget.onLogin?.call(
        _loginEmailController.text.trim(),
        _loginPasswordController.text.trim(),
      );
    }
  }

  void _handleRegister() {
    if (_registerFormKey.currentState!.validate()) {
      if (_registerPasswordController.text !=
          _registerPasswordConfirmationController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.labels?.passwordsDoNotMatch ?? 'Passwords do not match',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onRegister?.call(
        _registerNameController.text.trim(),
        _registerEmailController.text.trim(),
        _registerPasswordController.text.trim(),
        _registerPasswordConfirmationController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? LoginScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      showCartButton: false, // Login page doesn't need cart button
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF111827) // gray-900
              : const Color(0xFF78350F), // amber-900
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Responsive.scale(context, AppTheme.spacingLG),
            ), // p-4
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.scale(context, 448),
              ), // max-w-md
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937) // gray-800
                      : Colors.white,
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  border: Border.all(
                    color: const Color(0xFFD97706), // amber-500
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Close Button
                    Positioned(
                      top: Responsive.scale(
                        context,
                        AppTheme.spacingLG,
                      ), // top-4
                      right: Responsive.scale(
                        context,
                        AppTheme.spacingLG,
                      ), // right-4
                      child: IconButton(
                        onPressed: widget.onClose,
                        icon: Icon(
                          Icons.close,
                          size: Responsive.scale(context, 24), // w-6 h-6
                          color: isDark
                              ? const Color(0xFF9CA3AF) // gray-400
                              : const Color(0xFF9CA3AF), // gray-400
                        ),
                      ),
                    ),

                    // Form Content
                    Padding(
                      padding: EdgeInsets.all(
                        Responsive.scale(context, AppTheme.spacingXXL * 2),
                      ), // p-8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Section
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingLG * 1.5,
                            ), // mb-6
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLogin
                                      ? labels.welcomeBack
                                      : labels.createAccount,
                                  style:
                                      AppTextStyles.titleMediumStyle(
                                        color: isDark
                                            ? Colors.white
                                            : const Color(
                                                0xFF111827,
                                              ), // gray-900
                                        // font-weight: regular (default)
                                      ).copyWith(
                                        fontSize:
                                            AppTextStyles.text2XL, // text-2xl
                                      ),
                                ),
                                const SizedBox(
                                  height: AppTheme.spacingSM,
                                ), // mb-2
                                Text(
                                  _isLogin
                                      ? labels.signInAccount
                                      : labels.createAccountDescription,
                                  style: AppTextStyles.bodySmallStyle(
                                    color: isDark
                                        ? const Color(0xFF9CA3AF) // gray-400
                                        : const Color(0xFF4B5563), // gray-600
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Login Form
                          if (_isLogin) _buildLoginForm(isDark, labels),

                          // Register Form
                          if (!_isLogin) _buildRegisterForm(isDark, labels),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark, LoginScreenLabels labels) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          _buildEmailField(
            controller: _loginEmailController,
            label: labels.email,
            placeholder: labels.nameExample,
            isDark: isDark,
            isRequired: true,
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Password Field
          _buildPasswordField(
            controller: _loginPasswordController,
            label: labels.password,
            placeholder: labels.enterYourPassword,
            isDark: isDark,
            showPassword: _showPassword,
            onTogglePassword: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            isRequired: true,
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Login Button
          AppButton(
            text: widget.loading ? labels.loading : labels.signIn,
            onPressed: widget.loading ? null : _handleLogin,
            size: AppButtonSize.medium,
          ),

          // Error Message
          if (widget.error != null && widget.error!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLG), // mt-4
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLG,
                vertical: AppTheme.spacingSM,
              ), // py-2 px-4
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF991B1B).withValues(
                        alpha: 0.3,
                      ) // red-900/30
                    : const Color(0xFFFEF2F2), // red-50
                borderRadius: AppTheme.borderRadiusLargeValue,
              ),
              child: Text(
                widget.error!,
                style: AppTextStyles.bodySmallStyle(
                  color: isDark
                      ? const Color(0xFFF87171) // red-400
                      : const Color(0xFFDC2626), // red-600
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Links
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingLG), // mt-4
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: '${labels.dontHaveAccount} ',
                    style: AppTextStyles.bodySmallStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF) // gray-400
                          : const Color(0xFF4B5563), // gray-600
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogin = false;
                            });
                          },
                          child: Text(
                            labels.signUp,
                            style: AppTextStyles.bodySmallStyle(
                              color: const Color(0xFFD97706), // amber-600
                              fontWeight: AppTextStyles.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM), // space-y-2
                AppButton(
                  text: labels.continueAsGuest,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: widget.onContinueAsGuest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(bool isDark, LoginScreenLabels labels) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Field
          _buildTextField(
            controller: _registerNameController,
            label: labels.fullName,
            placeholder: labels.enterFullName,
            isDark: isDark,
            isRequired: true,
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Email Field
          _buildEmailField(
            controller: _registerEmailController,
            label: labels.email,
            placeholder: labels.nameExample,
            isDark: isDark,
            isRequired: true,
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Password Field
          _buildPasswordField(
            controller: _registerPasswordController,
            label: labels.password,
            placeholder: labels.enterYourPassword,
            isDark: isDark,
            showPassword: _showPassword,
            onTogglePassword: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            isRequired: true,
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Confirm Password Field
          _buildPasswordField(
            controller: _registerPasswordConfirmationController,
            label: labels.confirmPassword,
            placeholder: labels.confirmPassword,
            isDark: isDark,
            showPassword: _showConfirmPassword,
            onTogglePassword: () {
              setState(() {
                _showConfirmPassword = !_showConfirmPassword;
              });
            },
            isRequired: true,
            showToggle: false, // Don't show toggle for confirm password
          ),
          const SizedBox(height: AppTheme.spacingLG * 1.25), // space-y-5
          // Register Button
          AppButton(
            text: widget.loading ? labels.loading : labels.createAccount,
            onPressed: widget.loading ? null : _handleRegister,
            size: AppButtonSize.medium,
          ),

          // Error Message
          if (widget.error != null && widget.error!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingLG), // mt-4
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLG,
                vertical: AppTheme.spacingSM,
              ), // py-2 px-4
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF991B1B).withValues(
                        alpha: 0.3,
                      ) // red-900/30
                    : const Color(0xFFFEF2F2), // red-50
                borderRadius: AppTheme.borderRadiusLargeValue,
              ),
              child: Text(
                widget.error!,
                style: AppTextStyles.bodySmallStyle(
                  color: isDark
                      ? const Color(0xFFF87171) // red-400
                      : const Color(0xFFDC2626), // red-600
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Links
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingLG), // mt-4
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: '${labels.alreadyHaveAccount} ',
                    style: AppTextStyles.bodySmallStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF) // gray-400
                          : const Color(0xFF4B5563), // gray-600
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogin = true;
                            });
                          },
                          child: Text(
                            labels.signIn,
                            style: AppTextStyles.bodySmallStyle(
                              color: const Color(0xFFD97706), // amber-600
                              fontWeight: AppTextStyles.medium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM), // space-y-2
                AppButton(
                  text: labels.continueAsGuest,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: widget.onContinueAsGuest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDark,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTextStyles.bodySmallStyle(
            color: isDark
                ? const Color(0xFFD1D5DB) // gray-300
                : const Color(0xFF374151), // gray-700
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151) // gray-700
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF4B5563) // gray-600
                    : const Color(0xFFD1D5DB), // gray-300
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: BorderSide(
                color: isDark
                    ? const Color(0xFF4B5563) // gray-600
                    : const Color(0xFFD1D5DB), // gray-300
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFF6D4C41), // brown-600
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLG, // px-4
              vertical: AppTheme.spacingMD, // py-3
            ),
            hintStyle: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEmailField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDark,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTextStyles.bodySmallStyle(
            color: isDark
                ? const Color(0xFFD1D5DB) // gray-300
                : const Color(0xFF374151), // gray-700
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151) // gray-700
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD, // pl-3
              vertical: AppTheme.spacingMD, // py-3
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                right: AppTheme.spacingSM,
              ), // pr-10
              child: Icon(
                Icons.email_outlined,
                size: 20, // h-5 w-5
                color: isDark
                    ? const Color(0xFF6B7280) // gray-500
                    : const Color(0xFF9CA3AF), // gray-400
              ),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMD), // pr-3
              child: Icon(
                Icons.email_outlined,
                size: 20, // h-5 w-5
                color: isDark
                    ? const Color(0xFF6B7280) // gray-500
                    : const Color(0xFF9CA3AF), // gray-400
              ),
            ),
            hintStyle: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required bool isDark,
    required bool showPassword,
    required VoidCallback onTogglePassword,
    bool isRequired = false,
    bool showToggle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: AppTextStyles.bodySmallStyle(
            color: isDark
                ? const Color(0xFFD1D5DB) // gray-300
                : const Color(0xFF374151), // gray-700
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // mb-2
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF374151) // gray-700
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
              borderSide: const BorderSide(
                color: Color(0xFFD97706), // amber-500
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD, // pl-10 or pl-3
              vertical: AppTheme.spacingMD, // py-3
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSM),
              child: Icon(
                Icons.lock_outline,
                size: 20, // h-5 w-5
                color: isDark
                    ? const Color(0xFF6B7280) // gray-500
                    : const Color(0xFF9CA3AF), // gray-400
              ),
            ),
            suffixIcon: showToggle
                ? Padding(
                    padding: const EdgeInsets.only(
                      right: AppTheme.spacingMD,
                    ), // pr-3
                    child: IconButton(
                      onPressed: onTogglePassword,
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: Responsive.scale(context, 20), // h-5 w-5
                        color: isDark
                            ? const Color(0xFF6B7280) // gray-500
                            : const Color(0xFF9CA3AF), // gray-400
                      ),
                    ),
                  )
                : null,
            hintStyle: AppTextStyles.bodyMediumStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF9CA3AF), // gray-400
            ),
          ),
          style: AppTextStyles.bodyMediumStyle(
            color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

/// LoginScreenLabels - Localization labels
class LoginScreenLabels {
  final String welcomeBack;
  final String signInAccount;
  final String email;
  final String password;
  final String nameExample;
  final String enterYourPassword;
  final String signIn;
  final String signUp;
  final String dontHaveAccount;
  final String alreadyHaveAccount;
  final String continueAsGuest;
  final String fullName;
  final String enterFullName;
  final String confirmPassword;
  final String createAccount;
  final String createAccountDescription;
  final String loading;
  final String passwordsDoNotMatch;

  const LoginScreenLabels({
    required this.welcomeBack,
    required this.signInAccount,
    required this.email,
    required this.password,
    required this.nameExample,
    required this.enterYourPassword,
    required this.signIn,
    required this.signUp,
    required this.dontHaveAccount,
    required this.alreadyHaveAccount,
    required this.continueAsGuest,
    required this.fullName,
    required this.enterFullName,
    required this.confirmPassword,
    required this.createAccount,
    required this.createAccountDescription,
    required this.loading,
    required this.passwordsDoNotMatch,
  });

  factory LoginScreenLabels.defaultLabels() {
    return LoginScreenLabels.forLanguage('en');
  }

  factory LoginScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return LoginScreenLabels(
      welcomeBack: isArabic ? 'مرحباً بعودتك' : 'Welcome Back',
      signInAccount: isArabic
          ? 'تسجيل الدخول إلى حسابك'
          : 'Sign in to your account',
      email: isArabic ? 'البريد الإلكتروني' : 'Email',
      password: isArabic ? 'كلمة المرور' : 'Password',
      nameExample: 'name@example.com',
      enterYourPassword: isArabic ? 'أدخل كلمة المرور' : 'Enter your password',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      signUp: isArabic ? 'سجل' : 'Sign Up',
      dontHaveAccount: isArabic ? 'ليس لديك حساب؟' : "Don't have an account?",
      alreadyHaveAccount: isArabic
          ? 'هل لديك حساب بالفعل؟'
          : 'Already have an account?',
      continueAsGuest: isArabic ? 'المتابعة كضيف' : 'Continue as Guest',
      fullName: isArabic ? 'الاسم الكامل' : 'Full Name',
      enterFullName: isArabic ? 'أدخل اسمك الكامل' : 'Enter your full name',
      confirmPassword: isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password',
      createAccount: isArabic ? 'إنشاء حساب' : 'Create Account',
      createAccountDescription: isArabic
          ? 'أنشئ حساباً جديداً للبدء'
          : 'Create a new account to get started',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      passwordsDoNotMatch: isArabic
          ? 'كلمات المرور غير متطابقة'
          : 'Passwords do not match',
    );
  }
}
