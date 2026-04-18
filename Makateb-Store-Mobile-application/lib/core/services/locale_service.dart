import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'http_config_service.dart';

/// LocaleService - Language and locale management
/// 
/// Handles language preferences and locale changes.
/// Equivalent to language management in bootstrap.js.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const String _languageKey = 'language';
  static const String _defaultLanguage = 'ar';

  Locale? _currentLocale;
  ValueNotifier<Locale>? _localeNotifier;

  /// Initialize locale service
  Future<void> initialize() async {
    // Get saved language from storage
    final savedLanguage = StorageService.instance.getString(_languageKey) ?? _defaultLanguage;
    
    // Parse locale from language code
    _currentLocale = _parseLocale(savedLanguage);
    
    // Create notifier for locale changes
    _localeNotifier = ValueNotifier<Locale>(_currentLocale!);
    
    // Listen to storage changes (equivalent to storage event listener)
    _setupStorageListener();
  }

  /// Parse language code to Locale
  Locale _parseLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ar':
        return const Locale('ar', 'SA');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('ar', 'SA');
    }
  }

  /// Get current locale
  Locale get currentLocale => _currentLocale ?? const Locale('ar', 'SA');

  /// Get current language code
  String get currentLanguageCode {
    return _currentLocale?.languageCode ?? _defaultLanguage;
  }

  /// Get locale notifier for listening to changes
  ValueNotifier<Locale>? get localeNotifier => _localeNotifier;

  /// Set locale and save to storage
  /// Equivalent to updating localStorage and Accept-Language header
  Future<void> setLocale(Locale locale) async {
    _currentLocale = locale;
    _localeNotifier?.value = locale;
    
    // Save language code to storage
    await StorageService.instance.setString(_languageKey, locale.languageCode);
    
    // Update HTTP config language
    final httpConfig = HttpConfigService.instance;
    if (httpConfig.isInitialized) {
      await httpConfig.setLanguage(locale.languageCode);
    }
  }

  /// Set locale by language code
  Future<void> setLanguage(String languageCode) async {
    final locale = _parseLocale(languageCode);
    await setLocale(locale);
  }

  /// Setup storage listener for language changes
  /// Equivalent to window.addEventListener('storage') in bootstrap.js
  void _setupStorageListener() {
    // Note: In Flutter, we use ValueNotifier instead of storage events
    // The listener is set up through the notifier system
    // Actual storage events would require platform channels
  }

  /// Get supported locales
  static const List<Locale> supportedLocales = [
    Locale('ar', 'SA'), // Arabic
    Locale('en', 'US'), // English
  ];

  /// Dispose resources
  void dispose() {
    _localeNotifier?.dispose();
    _localeNotifier = null;
  }
}



