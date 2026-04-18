import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../services/http_config_service.dart';
import 'cart_store.dart';
import 'wishlist_store.dart';

/// AuthState - State class for auth store
///
/// Contains authentication state managed by the auth store.
/// Equivalent to Vue Pinia auth store state.
class AuthState {
  final AppUser? user;
  final String? token;
  final bool isDarkMode;

  const AuthState({this.user, this.token, this.isDarkMode = false});

  /// Computed: Check if user is authenticated
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// Create a copy with updated fields
  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    String? token,
    bool clearToken = false,
    bool? isDarkMode,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// AuthStoreNotifier - StateNotifier for auth store
///
/// Equivalent to Vue Pinia auth store actions and state management.
/// Handles authentication, token management, and dark mode.
class AuthStoreNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthStoreNotifier(this._ref) : super(const AuthState()) {
    _loadFromStorage();
  }

  final ApiClient _api = ApiClient.instance;

  /// Storage keys
  static const String _keyUser = 'auth_user';
  static const String _keyToken = 'token';
  static const String _keyDarkMode = 'auth_darkMode';

  /// Load state from storage
  /// Equivalent to Vue's localStorage loading on initialization
  Future<void> _loadFromStorage() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) {
        await storage.initialize();
      }

      // Load user
      AppUser? user;
      final savedUser = storage.getString(_keyUser);
      if (savedUser != null) {
        try {
          user = AppUser.fromJson(
            jsonDecode(savedUser) as Map<String, dynamic>,
          );
        } catch (e) {
          debugPrint('Error parsing saved user: $e');
          await storage.remove(_keyUser);
        }
      }

      // Load token
      final token = storage.getString(_keyToken);

      // Load dark mode
      final darkModeStr = storage.getString(_keyDarkMode);
      final isDarkMode = darkModeStr == 'true';

      // Update state
      state = state.copyWith(user: user, token: token, isDarkMode: isDarkMode);

      // Restore axios authorization header if token exists
      // Equivalent to: window.axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
      if (token != null) {
        HttpConfigService.instance.setAuthToken(token);
      }

      // Apply dark mode on initialization
      // Equivalent to: applyDarkMode()
      // Note: In Flutter, theme is managed by MaterialApp, so this is handled differently
      // The isDarkMode state can be used to control ThemeMode
    } catch (e) {
      debugPrint('Error loading auth state from storage: $e');
    }
  }

  /// Save user to storage
  Future<void> _saveUser(AppUser? user) async {
    final storage = StorageService.instance;
    if (user != null) {
      await storage.setString(_keyUser, jsonEncode(user.toJson()));
    } else {
      await storage.remove(_keyUser);
    }
  }

  /// Save token to storage and update HTTP config
  Future<void> _saveToken(String? token) async {
    final storage = StorageService.instance;
    if (token != null) {
      await storage.setString(_keyToken, token);
      // Update HTTP config service (equivalent to axios header update)
      HttpConfigService.instance.setAuthToken(token);
    } else {
      await storage.remove(_keyToken);
      // Clear HTTP config service token
      HttpConfigService.instance.setAuthToken(null);
    }
  }

  /// Save dark mode to storage
  Future<void> _saveDarkMode(bool isDarkMode) async {
    final storage = StorageService.instance;
    await storage.setString(_keyDarkMode, isDarkMode.toString());
  }

  // ==================== Actions ====================

  /// Login
  /// Equivalent to Vue's login()
  ///
  /// [credentials] - Login credentials (email, password, etc.)
  /// Returns response data with access_token and user
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    try {
      final response = await _api.postJson('/login', body: credentials);
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid login response');
      }

      final token = response['access_token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = AppUser.fromJson(userData);

      // Update state
      state = state.copyWith(token: token, user: user);

      // Save to storage (automatically handled by watchers in Vue)
      await _saveToken(token);
      await _saveUser(user);

      // Sync guest cart and wishlist
      unawaited(_ref.read(cartStoreProvider.notifier).syncGuest());
      unawaited(_ref.read(wishlistStoreProvider.notifier).syncGuest());

      return response;
    } catch (error) {
      // Re-throw error for handling by caller
      rethrow;
    }
  }

  /// Register
  /// Equivalent to Vue's register()
  ///
  /// [data] - Registration data (name, email, password, etc.)
  /// Returns response data with access_token and user
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      // Enforce the simplified registration contract:
      // name, email, password, password_confirmation
      //
      // Some Laravel backends may still validate `role` as required. We do NOT
      // expose roles/admin in the UI; if the backend requires it, we retry with
      // a safe default role ("customer") so registration works.
      final payload = <String, dynamic>{
        'name': (data['name'] ?? '').toString().trim(),
        'email': (data['email'] ?? '').toString().trim(),
        'password': (data['password'] ?? '').toString(),
        'password_confirmation':
            (data['password_confirmation'] ??
                    data['passwordConfirmation'] ??
                    '')
                .toString(),
      };

      dynamic response;
      try {
        response = await _api.postJson('/register', body: payload);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('role') && msg.contains('required')) {
          // Compatibility retry for backends that still require role.
          response = await _api.postJson(
            '/register',
            body: {...payload, 'role': 'customer'},
          );
        } else {
          rethrow;
        }
      }
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid register response');
      }

      final token = response['access_token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      // Force non-admin experience in the app layer.
      final user = AppUser.fromJson(userData).copyWith(role: 'customer');

      // Update state
      state = state.copyWith(token: token, user: user);

      // Save to storage
      await _saveToken(token);
      await _saveUser(user);

      // Sync guest cart and wishlist
      unawaited(_ref.read(cartStoreProvider.notifier).syncGuest());
      unawaited(_ref.read(wishlistStoreProvider.notifier).syncGuest());

      return response;
    } catch (error) {
      // Re-throw error for handling by caller
      rethrow;
    }
  }

  /// Logout
  /// Equivalent to Vue's logout()
  ///
  /// Updates state synchronously to trigger immediate UI rebuild,
  /// then performs async cleanup operations in the background.
  Future<void> logout() async {
    // Use clear flags to ensure these are actually set to null in the new state
    state = state.copyWith(clearUser: true, clearToken: true);

    // Perform async cleanup operations in the background (don't block UI update)
    // Use unawaited to fire-and-forget, or await if you need to wait
    _performLogoutCleanup();
  }

  /// Perform async logout cleanup (API call, storage clearing)
  Future<void> _performLogoutCleanup() async {
    try {
      // Best-effort API logout. Even if it fails, we still clear local session.
      await _api.postJson('/logout');
    } catch (error) {
      debugPrint('Logout error: $error');
    } finally {
      // Clear storage (async, but state is already cleared above)
      await _saveToken(null);
      await _saveUser(null);
    }
  }

  /// Fetch current user
  /// Equivalent to Vue's fetchUser()
  ///
  /// Fetches user data from server and checks if user is blocked.
  /// If user is blocked, logs out and redirects to blocked page.
  Future<AppUser> fetchUser() async {
    try {
      final response = await _api.getJson('/user');
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid user response');
      }
      final user = AppUser.fromJson(response);

      // Check if user is blocked and handle redirect
      // Equivalent to: if (response.data.is_blocked) { logout(); window.location.href = '/blocked'; }
      if (user.isBlocked == true) {
        await logout();
        // Note: Navigation to /blocked should be handled by the router/UI layer
        // This store only manages state, not navigation
        throw Exception('User is blocked');
      }

      // Update state
      state = state.copyWith(user: user);
      await _saveUser(user);

      return user;
    } catch (error) {
      // If 401, logout (token expired/invalid)
      // Equivalent to: if (error.response?.status === 401) { logout(); }
      if (error.toString().contains('401') ||
          error.toString().contains('Unauthorized')) {
        await logout();
      }
      rethrow;
    }
  }

  /// Update user profile
  /// Updates user data in the store and persists it
  Future<void> updateUser({
    String? name,
    String? email,
    String? bio,
    String? phone,
    String? location,
    String? avatarUrl,
    bool? isPrivate,
  }) async {
    if (state.user == null) return;

    // Get current additional data or create new map
    final currentAdditionalData = Map<String, dynamic>.from(
      state.user!.additionalData ?? {},
    );

    // Update additional data with new values
    if (bio != null) currentAdditionalData['bio'] = bio;
    if (phone != null) currentAdditionalData['phone'] = phone;
    if (location != null) currentAdditionalData['location'] = location;
    if (avatarUrl != null) currentAdditionalData['avatarUrl'] = avatarUrl;
    if (isPrivate != null) currentAdditionalData['isPrivate'] = isPrivate;

    // Create updated user
    final updatedUser = state.user!.copyWith(
      name: name ?? state.user!.name,
      email: email ?? state.user!.email,
      additionalData: currentAdditionalData,
    );

    // Update state
    state = state.copyWith(user: updatedUser);
    await _saveUser(updatedUser);
  }

  /// Toggle dark mode
  /// Equivalent to Vue's toggleDarkMode()
  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    await _saveDarkMode(newValue);
    // Note: Theme application is handled by MaterialApp in Flutter
    // The UI layer should watch this state and update ThemeMode accordingly
  }

  /// Set dark mode
  /// Equivalent to Vue's setDarkMode()
  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    await _saveDarkMode(value);
    // Note: Theme application is handled by MaterialApp in Flutter
  }

  /// Initialize session
  /// Equivalent to Vue's initializeSession()
  ///
  /// Fetches user if token exists but user is null.
  /// Handles token expiration.
  Future<void> initializeSession() async {
    // If we have a token but no user data, fetch user from server
    if (state.token != null && state.user == null) {
      try {
        await fetchUser();
      } catch (error) {
        // If fetch fails (e.g., token expired), clear session
        // Equivalent to: if (error.response?.status === 401 || error.response?.status === 403) { logout(); }
        if (error.toString().contains('401') ||
            error.toString().contains('403') ||
            error.toString().contains('Unauthorized') ||
            error.toString().contains('Forbidden')) {
          await logout();
        }
      }
    }
    // If we have both token and user, session is already restored from storage
  }

  // NOTE: Previously this file had mock API methods. Those were removed and
  // replaced with real Laravel API calls via ApiClient.
}

/// AuthStoreProvider - Riverpod provider for auth store
///
/// This is the main provider that exposes the auth store state and actions.
final authStoreProvider = StateNotifierProvider<AuthStoreNotifier, AuthState>(
  (ref) => AuthStoreNotifier(ref),
);

/// Computed/Selector Providers
///
/// These providers compute derived values from the auth store state.
/// Equivalent to Vue's computed properties.

/// Is authenticated provider
/// Equivalent to Vue's isAuthenticated computed
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).isAuthenticated;
});

/// User provider (nullable)
final authUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStoreProvider).user;
});

/// Token provider
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStoreProvider).token;
});

/// Dark mode provider
final authDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(authStoreProvider).isDarkMode;
});
