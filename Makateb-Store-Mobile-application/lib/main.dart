import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme.dart';
import 'core/services/bootstrap_service.dart';
import 'core/services/api_config.dart';
import 'core/services/http_config_service.dart';
import 'core/services/locale_service.dart';
import 'core/stores/auth_store.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/localization_service.dart';
import 'router/app_router.dart';

/// Main entry point of the Flutter application
///
/// Equivalent to Vue's app.js entry file.
/// Handles app initialization, error handling, and theme setup.
///
/// Bootstrap initialization (equivalent to bootstrap.js) is called here.
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar to transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize bootstrap service (equivalent to bootstrap.js)
  // This sets up storage, HTTP config, locale, and restores tokens
  try {
    await BootstrapService.instance.initialize(
      apiBaseUrl: ApiConfig.baseUrl,
      // csrfToken: null, // CSRF token would come from meta tag in web, set here if needed
    );
    // Ensure HttpConfigService has the full base URL for the API client.
    HttpConfigService.instance.setBaseUrl(ApiConfig.baseUrl);
  } catch (e) {
    debugPrint('Bootstrap initialization error: $e');
    // Continue app launch even if bootstrap fails
    // Error will be handled by AppLayout
  }

  // Initialize localization service
  try {
    await LocalizationService().initialize();
  } catch (e) {
    debugPrint('LocalizationService initialization error: $e');
    // Continue app launch even if localization init fails
  }

  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log error details (equivalent to Vue's errorHandler)
    debugPrint('Global Flutter error: ${details.exception}');
    debugPrint('Error details: ${details.informationCollector}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Handle errors from platform channels
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Run the app with error boundary and Riverpod ProviderScope
  runApp(const ProviderScope(child: App()));
}

/// Root application widget
///
/// Equivalent to Vue's App component.
/// Wraps the entire app with theme, localization, and error handling.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Listen to locale changes from both LocaleService and LocalizationService
    LocaleService.instance.localeNotifier?.addListener(_onLocaleChanged);
    LocalizationService().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.instance.localeNotifier?.removeListener(_onLocaleChanged);
    LocalizationService().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {
      // Rebuild when locale changes
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch dark mode state from auth store
    final isDarkMode = ref.watch(authDarkModeProvider);

    // Use ValueListenableBuilder to react to localeNotifier changes for immediate updates
    final localeService = LocalizationService();

    return ValueListenableBuilder<Locale>(
      valueListenable: localeService.localeNotifier,
      builder: (context, currentLocale, _) {
        return MaterialApp.router(
          // App metadata
          title: 'Makateb Store',
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          // Use light mode by default, switch to dark when isDarkMode is true
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Router configuration
          // Use GoRouter for navigation (equivalent to Vue Router)
          routerConfig: AppRouter.router,

          // Localization configuration
          // Locale is managed by LocalizationService, updated via ValueNotifier
          localizationsDelegates: const [
            AppLocalizationsDelegate(), // JSON-based localization
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocalizationService.supportedLocales,
          locale:
              currentLocale, // Use current locale from LocalizationService (reactive)
        );
      },
    );
  }
}
