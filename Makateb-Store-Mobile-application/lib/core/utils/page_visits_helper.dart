import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// PageVisitsConstants - Storage constants
class PageVisitsConstants {
  PageVisitsConstants._();

  /// Storage key for page visits
  static const String storageKey = 'page_visits';
}

/// PageVisitData - Page visit data model
///
/// Represents a single page visit entry.
/// Equivalent to Vue's page visit object structure.
class PageVisitData {
  final String name;
  final String path;
  final int visits;
  final String lastVisit;

  PageVisitData({
    required this.name,
    required this.path,
    required this.visits,
    required this.lastVisit,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'visits': visits,
      'last_visit': lastVisit,
    };
  }

  /// Create from JSON map
  factory PageVisitData.fromJson(Map<String, dynamic> json) {
    return PageVisitData(
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      visits: (json['visits'] as num?)?.toInt() ?? 0,
      lastVisit: json['last_visit'] as String? ?? '',
    );
  }

  /// Create a copy with updated fields
  PageVisitData copyWith({
    String? name,
    String? path,
    int? visits,
    String? lastVisit,
  }) {
    return PageVisitData(
      name: name ?? this.name,
      path: path ?? this.path,
      visits: visits ?? this.visits,
      lastVisit: lastVisit ?? this.lastVisit,
    );
  }
}

/// PageVisitsHelper - Page visit tracking utility
///
/// Equivalent to Vue's pageVisits.js utility file.
/// Tracks page visits using local storage.
class PageVisitsHelper {
  PageVisitsHelper._();

  /// Get all page visits from storage
  ///
  /// Equivalent to Vue's getPageVisits() function.
  ///
  /// Returns map of page paths to PageVisitData, or empty map on error
  ///
  /// Example:
  /// ```dart
  /// final visits = PageVisitsHelper.getPageVisits();
  /// ```
  static Map<String, PageVisitData> getPageVisits() {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return {};

      final stored = storage.getString(PageVisitsConstants.storageKey);
      if (stored == null || stored.isEmpty) return {};

      final Map<String, dynamic> visitsMap = jsonDecode(stored);
      return visitsMap.map(
        (key, value) => MapEntry(
          key,
          PageVisitData.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (error) {
      debugPrint('Error reading page visits: $error');
      return {};
    }
  }

  /// Track a page visit
  ///
  /// Equivalent to Vue's trackPageVisit() function.
  ///
  /// [pagePath] - The page path (e.g., '/dashboard', '/product/123')
  /// [pageName] - The page name (e.g., 'Dashboard', 'Product Details')
  /// Returns PageVisitData for the tracked page, or null on error
  ///
  /// Example:
  /// ```dart
  /// final visitData = await PageVisitsHelper.trackPageVisit(
  ///   '/dashboard',
  ///   'Dashboard',
  /// );
  /// ```
  static Future<PageVisitData?> trackPageVisit(
    String pagePath,
    String pageName,
  ) async {
    try {
      final visits = getPageVisits();
      final now = DateTime.now().toIso8601String();

      PageVisitData visitData;
      if (!visits.containsKey(pagePath)) {
        visitData = PageVisitData(
          name: pageName,
          path: pagePath,
          visits: 0,
          lastVisit: now,
        );
      } else {
        visitData = visits[pagePath]!;
      }

      // Increment visits and update last visit
      visitData = visitData.copyWith(
        visits: visitData.visits + 1,
        lastVisit: now,
      );

      // Save to storage
      visits[pagePath] = visitData;
      final visitsJson = jsonEncode(
        visits.map((key, value) => MapEntry(key, value.toJson())),
      );

      final storage = StorageService.instance;
      if (storage.isInitialized) {
        await storage.setString(PageVisitsConstants.storageKey, visitsJson);
      }

      return visitData;
    } catch (error) {
      debugPrint('Error tracking page visit: $error');
      return null;
    }
  }

  /// Get visit count for a specific page
  ///
  /// Equivalent to Vue's getPageVisitCount() function.
  ///
  /// [pagePath] - The page path to get visit count for
  /// Returns visit count for the page, or 0 if not found
  ///
  /// Example:
  /// ```dart
  /// final count = PageVisitsHelper.getPageVisitCount('/dashboard');
  /// ```
  static int getPageVisitCount(String pagePath) {
    final visits = getPageVisits();
    return visits[pagePath]?.visits ?? 0;
  }

  /// Get all pages with their visit counts
  ///
  /// Equivalent to Vue's getAllPageVisits() function.
  ///
  /// Returns map of page paths to PageVisitData
  ///
  /// Example:
  /// ```dart
  /// final allVisits = PageVisitsHelper.getAllPageVisits();
  /// ```
  static Map<String, PageVisitData> getAllPageVisits() {
    return getPageVisits();
  }

  /// Clear all page visits (for testing)
  ///
  /// Equivalent to Vue's clearPageVisits() function.
  ///
  /// Example:
  /// ```dart
  /// await PageVisitsHelper.clearPageVisits();
  /// ```
  static Future<void> clearPageVisits() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return;
      await storage.remove(PageVisitsConstants.storageKey);
    } catch (error) {
      debugPrint('Error clearing page visits: $error');
    }
  }
}


