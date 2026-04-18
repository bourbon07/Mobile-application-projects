import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// HttpConfigService - HTTP client configuration
///
/// Equivalent to Vue's axios configuration in bootstrap.js.
/// Provides structure for HTTP client setup without making actual API calls.
///
/// Note: This is a configuration service only. Actual HTTP calls are excluded
/// as per requirements (no API calls).
class HttpConfigService {
  HttpConfigService._();
  static final HttpConfigService instance = HttpConfigService._();

  // Configuration values
  String? _baseUrl;
  String? _csrfToken;
  String? _authToken;
  String? _guestId;
  String _language = 'ar'; // Default language

  /// Initialize HTTP configuration
  /// Equivalent to setting up axios defaults in bootstrap.js
  Future<void> initialize({String? baseUrl, String? csrfToken}) async {
    // Set base URL (equivalent to window.axios.defaults.baseURL)
    _baseUrl = baseUrl ?? '/api';

    // Set CSRF token (equivalent to reading from meta tag)
    _csrfToken = csrfToken;

    // Restore language from storage (equivalent to localStorage.getItem('language'))
    final storage = StorageService.instance;
    if (storage.isInitialized) {
      _language = storage.getString('language') ?? 'ar';
    }

    // Restore auth token from storage (equivalent to localStorage.getItem('token'))
    if (storage.isInitialized) {
      _authToken = storage.getString('token');

      // Restore or generate guest ID
      _guestId = storage.getString('guest_id');
      if (_guestId == null) {
        final random = (1000 + (8999 * (DateTime.now().microsecond / 1000000)))
            .toInt();
        _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}_$random';
        await storage.setString('guest_id', _guestId!);
      }
    }
  }

  /// Get base URL
  String? get baseUrl => _baseUrl;

  /// Set base URL (e.g. https://makateb.metafortech.com/api)
  void setBaseUrl(String? url) {
    _baseUrl = url;
  }

  /// Get CSRF token
  String? get csrfToken => _csrfToken;

  /// Set CSRF token
  void setCsrfToken(String? token) {
    _csrfToken = token;
  }

  /// Get authorization token
  String? get authToken => _authToken;

  /// Set authorization token
  void setAuthToken(String? token) {
    _authToken = token;
    // Save to storage (equivalent to localStorage.setItem('token'))
    if (token != null) {
      StorageService.instance.setString('token', token);
    } else {
      StorageService.instance.remove('token');
    }
  }

  /// Get current language
  String get language => _language;

  /// Set language and update storage
  /// Equivalent to updating Accept-Language header and localStorage
  Future<void> setLanguage(String lang) async {
    _language = lang;
    await StorageService.instance.setString('language', lang);
  }

  /// Get default headers
  /// Equivalent to window.axios.defaults.headers.common
  Map<String, String> get defaultHeaders {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': _language,
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
    };

    // Add CSRF token if available
    if (_csrfToken != null) {
      headers['X-CSRF-TOKEN'] = _csrfToken!;
    }

    // Add authorization token if available
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add guest ID if available
    var guestId = _guestId;
    if (guestId == null) {
      // Fallback: Generate guest ID if dealing with race conditions or init failure
      final random = (1000 + (8999 * (DateTime.now().microsecond / 1000000)))
          .toInt();
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}_$random';
      _guestId = guestId;
      // Try to persist asynchronously
      StorageService.instance.setString('guest_id', guestId);
      debugPrint('[HttpConfigService] Generated fallback guest_id: $guestId');
    }

    headers['X-Guest-Id'] = guestId;

    return headers;
  }

  /// Check if configuration is initialized
  bool get isInitialized => _baseUrl != null;
}
