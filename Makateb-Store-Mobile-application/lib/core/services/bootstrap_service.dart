import 'package:flutter/foundation.dart';
import 'storage_service.dart';
import 'http_config_service.dart';
import 'locale_service.dart';

/// BootstrapService - Application initialization service
/// 
/// Equivalent to Vue's bootstrap.js file.
/// Handles all app initialization logic including:
/// - Storage initialization
/// - HTTP client configuration
/// - Language/locale setup
/// - Token restoration
class BootstrapService {
  BootstrapService._();
  static final BootstrapService instance = BootstrapService._();

  bool _isInitialized = false;

  /// Check if bootstrap is complete
  bool get isInitialized => _isInitialized;

  /// Initialize the application
  /// 
  /// Equivalent to bootstrap.js initialization logic.
  /// This method sets up all global configurations.
  Future<void> initialize({
    String? apiBaseUrl,
    String? csrfToken,
  }) async {
    if (_isInitialized) {
      debugPrint('BootstrapService: Already initialized');
      return;
    }

    try {
      debugPrint('BootstrapService: Starting initialization...');

      // 1. Initialize storage service (localStorage equivalent)
      debugPrint('BootstrapService: Initializing storage...');
      await StorageService.instance.initialize();

      // 2. Initialize HTTP configuration (axios equivalent)
      debugPrint('BootstrapService: Initializing HTTP config...');
      await HttpConfigService.instance.initialize(
        baseUrl: apiBaseUrl,
        csrfToken: csrfToken,
      );

      // 3. Initialize locale service (language management)
      debugPrint('BootstrapService: Initializing locale service...');
      await LocaleService.instance.initialize();

      // 4. Restore authentication token if exists
      // Equivalent to: const savedToken = localStorage.getItem('token')
      final savedToken = StorageService.instance.getString('token');
      if (savedToken != null) {
        debugPrint('BootstrapService: Restoring auth token...');
        HttpConfigService.instance.setAuthToken(savedToken);
      }

      _isInitialized = true;
      debugPrint('BootstrapService: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('BootstrapService: Initialization error: $e');
      debugPrint('BootstrapService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Reset bootstrap (for testing or logout scenarios)
  Future<void> reset() async {
    _isInitialized = false;
    await StorageService.instance.clear();
    await HttpConfigService.instance.initialize();
    await LocaleService.instance.initialize();
    _isInitialized = true;
  }
}



