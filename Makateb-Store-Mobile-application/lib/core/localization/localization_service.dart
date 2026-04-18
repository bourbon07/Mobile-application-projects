import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// LocalizationService - Manages app locale state
///
/// Provides methods to change locale and exposes current locale state.
/// Persists locale preference to storage.
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  /// Current locale
  Locale _currentLocale = const Locale('ar', 'SA'); // Default to Arabic

  /// Locale notifier for reactive updates
  final ValueNotifier<Locale> _localeNotifier = ValueNotifier<Locale>(
    const Locale('ar', 'SA'),
  );

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get locale notifier
  ValueNotifier<Locale> get localeNotifier => _localeNotifier;

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('ar', 'SA'), // Arabic (Saudi Arabia)
    Locale('en', 'US'), // English (United States)
  ];

  /// Initialize service and load saved locale
  Future<void> initialize() async {
    try {
      final savedLanguage = StorageService.instance.getString('language');
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        await setLocale(_parseLocale(savedLanguage));
      } else {
        // Default to Arabic
        await setLocale(const Locale('ar', 'SA'));
      }
    } catch (e) {
      debugPrint('Error initializing LocalizationService: $e');
      // Default to Arabic on error
      await setLocale(const Locale('ar', 'SA'));
    }
  }

  /// Change locale
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      debugPrint('Unsupported locale: $locale');
      return;
    }

    _currentLocale = locale;
    _localeNotifier.value = locale;

    // Persist to storage
    try {
      await StorageService.instance.setString('language', locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale to storage: $e');
    }
  }

  /// Change locale by language code
  Future<void> changeLocale(String languageCode) async {
    final locale = _parseLocale(languageCode);
    await setLocale(locale);
  }

  /// Parse language code to Locale
  Locale _parseLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return const Locale('ar', 'SA');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ar', 'SA'); // Default to Arabic
    }
  }

  /// Check if current locale is RTL
  bool get isRTL => _currentLocale.languageCode == 'ar';

  /// Get current language code
  String get currentLanguageCode => _currentLocale.languageCode;
}

/// LocalizationService provider
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService();
});

/// Current locale provider - for immediate access
final currentLocaleProvider = Provider<Locale>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.currentLocale;
});

/// Is RTL provider
final isRTLProvider = Provider<bool>((ref) {
  final service = ref.watch(localizationServiceProvider);
  return service.isRTL;
});


