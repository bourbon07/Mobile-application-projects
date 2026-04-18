import 'package:flutter/foundation.dart';
import '../api_client.dart';

/// LaravelWishlistApiService
///
/// API service for wishlist operations (add, remove, fetch).
class LaravelWishlistApiService {
  LaravelWishlistApiService({ApiClient? api})
    : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetch wishlist items from API.
  ///
  /// Returns list of wishlist items with product/package details.
  Future<List<dynamic>> fetchWishlist() async {
    try {
      final res = await _api.getJson('/wishlist');
      if (kDebugMode) {
        debugPrint(
          '[WishlistAPI] Fetch wishlist response type: ${res.runtimeType}',
        );
        debugPrint('[WishlistAPI] Fetch wishlist response: $res');
      }

      if (res is List) {
        if (kDebugMode) {
          debugPrint(
            '[WishlistAPI] Found ${res.length} items in wishlist (direct list)',
          );
        }
        return res;
      }
      // Laravel might return { data: [...] } or { wishlist: [...] } or { items: [...] }
      if (res is Map) {
        // Try common top-level keys
        var data = res['items'] ?? res['data'] ?? res['wishlist'];

        // If data is a Map, it might contain the list inside or the keys themselves
        if (data is Map) {
          final items = data['items'] ?? data['wishlist_items'] ?? data['data'];

          if (items is List) {
            data = items;
          } else {
            // Merge products and packages if they exist separately
            final products = data['products'];
            final packages = data['packages'];
            final merged = <dynamic>[];
            if (products is List) merged.addAll(products);
            if (packages is List) merged.addAll(packages);
            data = merged;
          }
        } else if (data == null) {
          // If top-level was not a known list, check res for products/packages
          final products = res['products'];
          final packages = res['packages'];
          final merged = <dynamic>[];
          if (products is List) merged.addAll(products);
          if (packages is List) merged.addAll(packages);
          data = merged;
        }

        if (data is List) {
          if (kDebugMode) {
            debugPrint(
              '[WishlistAPI] Found ${data.length} items in wishlist (from map)',
            );
          }
          return data;
        }
        if (kDebugMode) {
          debugPrint(
            '[WishlistAPI] Response is Map but no list found. Keys: ${res.keys.toList()}',
          );
        }
      }
      if (kDebugMode) {
        debugPrint('[WishlistAPI] No items found in wishlist response');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistAPI] Wishlist fetchWishlist failed: $e');
      }
      return [];
    }
  }

  /// Add product to wishlist.
  ///
  /// [productId] - Product ID to add
  Future<Map<String, dynamic>> addProductToWishlist(String productId) async {
    try {
      final res = await _api.postJson(
        '/wishlist',
        body: {'product_id': productId},
      );

      if (res is Map &&
          (res['items'] != null ||
              res['data'] != null ||
              res['wishlist'] != null)) {
        return res as Map<String, dynamic>;
      } else if (res is List) {
        return {'items': res};
      }

      return res is Map ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist addProductToWishlist failed: $e');
      rethrow;
    }
  }

  /// Add package to wishlist.
  ///
  /// [packageId] - Package ID to add
  Future<Map<String, dynamic>> addPackageToWishlist(String packageId) async {
    try {
      final res = await _api.postJson(
        '/wishlist',
        body: {'package_id': packageId},
      );

      if (res is Map &&
          (res['items'] != null ||
              res['data'] != null ||
              res['wishlist'] != null)) {
        return res as Map<String, dynamic>;
      } else if (res is List) {
        return {'items': res};
      }

      return res is Map ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist addPackageToWishlist failed: $e');
      rethrow;
    }
  }

  /// Remove product from wishlist.
  ///
  /// [productId] - Product ID to remove
  Future<void> removeProductFromWishlist(String productId) async {
    try {
      await _api.deleteJson('/wishlist/product/$productId');
    } catch (e) {
      // Try alternative endpoint format
      try {
        await _api.deleteJson('/wishlist', query: {'product_id': productId});
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('Wishlist removeProductFromWishlist failed: $e2');
        }
        rethrow;
      }
    }
  }

  /// Remove package from wishlist.
  ///
  /// [packageId] - Package ID to remove
  Future<void> removePackageFromWishlist(String packageId) async {
    try {
      await _api.deleteJson('/wishlist/package/$packageId');
    } catch (e) {
      // Try alternative endpoint format
      try {
        await _api.deleteJson('/wishlist', query: {'package_id': packageId});
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('Wishlist removePackageFromWishlist failed: $e2');
        }
        rethrow;
      }
    }
  }

  /// Check if product is in wishlist.
  ///
  /// [productId] - Product ID to check
  Future<bool> isProductInWishlist(String productId) async {
    try {
      final wishlist = await fetchWishlist();
      return wishlist.any((item) {
        if (item is Map) {
          return item['product_id']?.toString() == productId ||
              item['product']?['id']?.toString() == productId;
        }
        return false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist isProductInWishlist failed: $e');
      return false;
    }
  }

  /// Check if package is in wishlist.
  ///
  /// [packageId] - Package ID to check
  Future<bool> isPackageInWishlist(String packageId) async {
    try {
      final wishlist = await fetchWishlist();
      return wishlist.any((item) {
        if (item is Map) {
          return item['package_id']?.toString() == packageId ||
              item['package']?['id']?.toString() == packageId;
        }
        return false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist isPackageInWishlist failed: $e');
      return false;
    }
  }

  /// Sync guest wishlist items with server.
  Future<void> syncGuest(List<Map<String, dynamic>> items) async {
    try {
      await _api.postJson('/wishlist/sync-guest', body: {'items': items});
    } catch (e) {
      if (kDebugMode) debugPrint('Wishlist syncGuest failed: $e');
      rethrow;
    }
  }
}
