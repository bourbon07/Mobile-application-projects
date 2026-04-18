import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/locale_service.dart';
import '../services/http_config_service.dart';
import 'error_widget.dart';
import 'navbar.dart';
import 'notification_toast.dart';
// import 'notification_panel.dart'; // Removed unused import
import 'page_layout.dart';

/// AppLayout - Root layout widget
///
/// Equivalent to Vue's App.vue root component.
/// Handles the global layout structure, navigation setup, and initialization.
///
/// This widget serves as the root container for the entire application.
/// Structure matches Vue App.vue:
/// - Conditional Navbar
/// - Router view (main content)
/// - NotificationToast overlay
/// - ConfirmationModal overlay
class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  // Track initialization state
  bool _isInitialized = false;
  Object? _initializationError;
  final bool _showNavbar = true; // Will be determined by route

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupLocaleListener();
  }

  @override
  void dispose() {
    LocaleService.instance.localeNotifier?.removeListener(_onLocaleChanged);
    super.dispose();
  }

  /// Setup locale change listener
  /// Equivalent to Vue's watch(() => languageStore.currentLanguage)
  void _setupLocaleListener() {
    LocaleService.instance.localeNotifier?.addListener(_onLocaleChanged);
  }

  /// Handle locale changes
  /// Equivalent to Vue's watch callback that updates HTML attributes and axios headers
  void _onLocaleChanged() {
    final currentLang = LocaleService.instance.currentLanguageCode;

    // Update HTTP config language header (equivalent to axios header update)
    HttpConfigService.instance.setLanguage(currentLang);

    // Rebuild to update RTL/LTR direction
    if (mounted) {
      setState(() {});
    }
  }

  /// Initialize the application
  ///
  /// Equivalent to Vue's onMounted hook.
  /// Performs language initialization and session restoration.
  Future<void> _initializeApp() async {
    try {
      // Initialize language - ensure Arabic is default
      // Equivalent to: if (!localStorage.getItem('language')) { languageStore.setLanguage('ar'); }
      final storage = LocaleService.instance;
      if (storage.currentLanguageCode.isEmpty) {
        await storage.setLanguage('ar');
      } else {
        // Ensure language is set correctly
        final currentLang = storage.currentLanguageCode;
        // Update HTTP config language header
        await HttpConfigService.instance.setLanguage(currentLang);
      }

      // Initialize session - restore user if token exists
      // Equivalent to: await authStore.initializeSession();
      // Note: No API calls as per requirements, just check if token exists
      final token = HttpConfigService.instance.authToken;
      if (token != null) {
        debugPrint('Session token found, user session restored');
        // In a real app, you would validate the token here
        // (No API calls as per requirements)
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error, stackTrace) {
      // Handle initialization errors
      debugPrint('App initialization error: $error');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _initializationError = error;
          _isInitialized = true; // Show error UI
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error UI if initialization failed
    if (_initializationError != null) {
      return AppErrorWidget(
        error: _initializationError!,
        onRetry: () {
          setState(() {
            _initializationError = null;
            _isInitialized = false;
          });
          _initializeApp();
        },
      );
    }

    // Show loading state during initialization
    if (!_isInitialized) {
      return const AppLoadingWidget();
    }

    // Get current locale for RTL/LTR direction
    final currentLocale = LocaleService.instance.currentLocale;
    final isRTL = currentLocale.languageCode == 'ar';

    // Main app content
    // Equivalent to Vue template structure:
    // <div class="min-h-screen bg-white dark:bg-gray-900">
    //   <Navbar v-if="showNavbar" />
    //   <router-view />
    //   <NotificationToast />
    //   <ConfirmationModal />
    // </div>
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              // Notification Panel at the very top
              // Notification Panel removed to avoid duplicates (using NotificationToast instead)
              // const NotificationPanel(),

              // Navbar below the Notification Panel
              if (_showNavbar) const Navbar(),

              // Main content area (equivalent to <router-view />)
              const Expanded(child: AppContent()),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppContent - Main application content
///
/// Contains the actual app UI structure.
/// Equivalent to Vue's `<router-view />`.
/// This is where routing and main layout components would be placed.
class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    // This is where your router would render the current route
    // For now, showing a placeholder
    // NOTE: Replace with your actual router implementation as needed

    return Stack(
      children: [
        // Main content area (router view)
        // Use PageLayout for pages that need the cart button
        PageLayout(
          cartCount: 0, // Replace with actual cart count
          onCartTap: () {
            // Navigate to cart page - using empty callback as placeholder
            // Navigation will be handled by the actual screen implementations
          },
          isCartPage: false, // Set to true when on cart page
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppTheme.spacingLG),
                Text(
                  'Application Loaded',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  'AppLayout is ready',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Global overlay widgets (always present, shown when needed)
        // NotificationToast - equivalent to <NotificationToast />
        // Positioned at top-4 left-4/right-4 (handled internally by widget)
        const NotificationToast(),

        // ConfirmationModal - shown via ConfirmationModalService.showConfirmation()
        // No need to include in widget tree as it's displayed via showDialog
      ],
    );
  }
}

/// AppLoadingWidget - Loading state during initialization
///
/// Shows a loading indicator while the app is initializing.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text('Loading...', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
