import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AppLocalizations - JSON-based localization class
///
/// Loads translations from JSON files and provides localized string access.
/// Supports RTL for Arabic and follows Flutter best practices.
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Get localized string by key
  String translate(String key, [Map<String, String>? params]) {
    String value = _localizedStrings[key]?.toString() ?? key;

    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }

    return value;
  }

  /// Shorthand for translate
  String t(String key, [Map<String, String>? params]) {
    return translate(key, params);
  }

  /// Check if a key exists
  bool hasKey(String key) {
    return _localizedStrings.containsKey(key);
  }

  /// Load translations from JSON asset
  static Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);

    try {
      // Load JSON file based on locale
      final jsonString = await rootBundle.loadString(
        'lib/core/localization/${locale.languageCode}.json',
      );

      localizations._localizedStrings =
          json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Fallback to empty map if file not found
      debugPrint('Error loading localization for ${locale.languageCode}: $e');
      localizations._localizedStrings = <String, dynamic>{};
    }

    return localizations;
  }

  /// Get current instance from context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar';
  }
}

/// AppLocalizationsDelegate - LocalizationsDelegate for AppLocalizations
///
/// Handles loading and providing localized strings based on locale.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}


