import 'package:shared_preferences/shared_preferences.dart';

/// StorageService - Local storage equivalent
/// 
/// Equivalent to browser's localStorage.
/// Handles persistent storage of app data like tokens, language preferences, etc.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  /// Initialize storage service
  /// Must be called before using other methods
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if storage is initialized
  bool get isInitialized => _prefs != null;

  /// Get a string value
  String? getString(String key) {
    if (!isInitialized) return null;
    return _prefs!.getString(key);
  }

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    if (!isInitialized) return false;
    return await _prefs!.setString(key, value);
  }

  /// Get a boolean value
  bool? getBool(String key) {
    if (!isInitialized) return null;
    return _prefs!.getBool(key);
  }

  /// Set a boolean value
  Future<bool> setBool(String key, bool value) async {
    if (!isInitialized) return false;
    return await _prefs!.setBool(key, value);
  }

  /// Get an integer value
  int? getInt(String key) {
    if (!isInitialized) return null;
    return _prefs!.getInt(key);
  }

  /// Set an integer value
  Future<bool> setInt(String key, int value) async {
    if (!isInitialized) return false;
    return await _prefs!.setInt(key, value);
  }

  /// Remove a value
  Future<bool> remove(String key) async {
    if (!isInitialized) return false;
    return await _prefs!.remove(key);
  }

  /// Clear all stored values
  Future<bool> clear() async {
    if (!isInitialized) return false;
    return await _prefs!.clear();
  }

  /// Check if a key exists
  bool containsKey(String key) {
    if (!isInitialized) return false;
    return _prefs!.containsKey(key);
  }

  /// Get all keys
  Set<String> getAllKeys() {
    if (!isInitialized) return {};
    return _prefs!.getKeys();
  }
}



