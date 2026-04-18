/// API configuration for Laravel backend.
///
/// You can override at runtime:
/// - `flutter run --dart-define=API_BASE_URL=https://makateb.metafortech.com/api`
///
/// Default: https://makateb.metafortech.com/api
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;

    // Live production backend
    return 'https://makateb.metafortech.com/api';
  }
}
