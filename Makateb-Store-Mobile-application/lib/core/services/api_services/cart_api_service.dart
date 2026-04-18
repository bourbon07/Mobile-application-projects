import 'package:flutter/foundation.dart';
import '../api_client.dart';

/// LaravelCartApiService
///
/// API service for cart operations (add, update, remove, fetch).
class LaravelCartApiService {
  LaravelCartApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetch cart items from API.
  ///
  /// Returns list of cart items with product/package details.
  Future<List<dynamic>> fetchCart() async {
    try {
      final res = await _api.getJson('/cart');
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════');
        debugPrint(
          '[CartAPI] 🔍 FETCH CART - Response type: ${res.runtimeType}',
        );
        debugPrint('[CartAPI] 📦 Full response: $res');
        if (res is Map) {
          debugPrint('[CartAPI] 🔑 Map keys: ${res.keys.toList()}');
        }
      }

      if (res is List) {
        if (kDebugMode) {
          debugPrint('[CartAPI] ✅ Response is List with ${res.length} items');
          if (res.isNotEmpty) {
            debugPrint('[CartAPI] 📋 First item: ${res.first}');
          }
          debugPrint('═══════════════════════════════════════════');
        }
        return res;
      }
      // Backend CartController returns { items: [...], total: ... }
      if (res is Map) {
        // Try common top-level keys
        var data = res['items'] ?? res['data'] ?? res['cart'];

        if (kDebugMode) {
          debugPrint('[CartAPI] 🗺️ Extracted data type: ${data.runtimeType}');
          debugPrint('[CartAPI] 📊 Data content: $data');
        }

        // If data is a Map, it might contain the list inside (e.g. data['items'])
        if (data is Map) {
          if (kDebugMode) {
            debugPrint(
              '[CartAPI] 🗺️ Data is Map with keys: ${data.keys.toList()}',
            );
          }

          final items = data['items'] ?? data['cart_items'] ?? data['data'];
          if (items is List) {
            data = items;
            if (kDebugMode) {
              debugPrint('[CartAPI] ✅ Found items list: ${items.length} items');
            }
          } else {
            // Merge products and packages if they exist separately
            final products = data['products'];
            final packages = data['packages'];
            final merged = <dynamic>[];

            if (kDebugMode) {
              debugPrint('[CartAPI] 🔀 Merging products and packages');
              debugPrint('[CartAPI] Products: $products');
              debugPrint('[CartAPI] Packages: $packages');
            }

            if (products is List) {
              merged.addAll(products);
              if (kDebugMode) {
                debugPrint('[CartAPI] ➕ Added ${products.length} products');
              }
            }
            if (packages is List) {
              merged.addAll(packages);
              if (kDebugMode) {
                debugPrint('[CartAPI] ➕ Added ${packages.length} packages');
              }
            }
            data = merged;
          }
        }

        if (data is List) {
          if (kDebugMode) {
            debugPrint('[CartAPI] ✅ Final: ${data.length} items in cart');
            if (data.isNotEmpty) {
              debugPrint('[CartAPI] 📋 First item structure: ${data.first}');
            }
            debugPrint('═══════════════════════════════════════════');
          }
          return data;
        }
      }
      if (kDebugMode) {
        debugPrint('[CartAPI] ⚠️ No items found in response');
        debugPrint('═══════════════════════════════════════════');
      }
      return [];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[CartAPI] ❌ fetchCart failed: $e');
        debugPrint('[CartAPI] Stack: $stackTrace');
        debugPrint('═══════════════════════════════════════════');
      }
      return [];
    }
  }

  /// Add product to cart.
  ///
  /// [productId] - Product ID to add
  /// [quantity] - Quantity (default: 1)
  Future<Map<String, dynamic>> addProductToCart(
    String productId, {
    int quantity = 1,
  }) async {
    try {
      final res = await _api.postJson(
        '/cart',
        body: {'product_id': productId, 'quantity': quantity},
      );

      // If backend returns the full cart items list directly or wrapped
      if (res is Map &&
          (res['items'] != null ||
              res['data'] != null ||
              res['cart'] != null)) {
        return res as Map<String, dynamic>;
      } else if (res is List) {
        return {'items': res};
      }

      return res is Map ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      if (kDebugMode) debugPrint('Cart addProductToCart failed: $e');
      rethrow;
    }
  }

  /// Add package to cart.
  ///
  /// [packageId] - Package ID to add
  /// [quantity] - Quantity (default: 1) - Note: Backend currently doesn't support quantity for packages
  Future<Map<String, dynamic>> addPackageToCart(
    String packageId, {
    int quantity = 1,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          'Adding package to cart: packageId=$packageId, quantity=$quantity',
        );
      }
      // Backend uses /cart/package endpoint for packages
      final res = await _api.postJson(
        '/cart/package',
        body: {
          'package_id': packageId,
          // Note: Backend addPackageToCart doesn't accept quantity parameter
          // It always adds quantity 1 or increments if already exists
        },
      );
      if (kDebugMode) {
        debugPrint('Cart addPackageToCart response: $res');
      }

      // If backend returns the full cart items list directly or wrapped
      if (res is Map &&
          (res['items'] != null ||
              res['data'] != null ||
              res['cart'] != null)) {
        return res as Map<String, dynamic>;
      } else if (res is List) {
        return {'items': res};
      }

      return res is Map ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cart addPackageToCart failed: $e');
        debugPrint('Error type: ${e.runtimeType}');
        if (e is Exception) {
          debugPrint('Exception message: ${e.toString()}');
        }
      }
      rethrow;
    }
  }

  /// Update cart item quantity.
  ///
  /// [itemId] - Cart item ID
  /// [quantity] - New quantity
  Future<Map<String, dynamic>> updateQuantity(
    String itemId,
    int quantity,
  ) async {
    try {
      final res = await _api.putJson(
        '/cart/$itemId',
        body: {'quantity': quantity},
      );
      return res is Map ? Map<String, dynamic>.from(res) : {'success': true};
    } catch (e) {
      if (kDebugMode) debugPrint('Cart updateQuantity failed: $e');
      rethrow;
    }
  }

  /// Remove item from cart.
  ///
  /// [itemId] - Cart item ID to remove
  Future<void> removeFromCart(String itemId) async {
    try {
      await _api.deleteJson('/cart/$itemId');
    } catch (e) {
      if (kDebugMode) debugPrint('Cart removeFromCart failed: $e');
      rethrow;
    }
  }

  /// Clear entire cart.
  Future<void> clearCart() async {
    try {
      await _api.deleteJson('/cart');
    } catch (e) {
      if (kDebugMode) debugPrint('Cart clearCart failed: $e');
      rethrow;
    }
  }

  /// Sync guest cart items with server.
  Future<void> syncGuest(List<Map<String, dynamic>> items) async {
    try {
      await _api.postJson('/cart/sync-guest', body: {'items': items});
    } catch (e) {
      if (kDebugMode) debugPrint('Cart syncGuest failed: $e');
      rethrow;
    }
  }
}
