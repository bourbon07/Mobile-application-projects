import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Guest storage constants
///
/// Storage keys for guest cart and wishlist.
class GuestStorageConstants {
  GuestStorageConstants._();

  /// Storage key for guest cart
  static const String cartStorageKey = 'guest_cart';

  /// Storage key for guest wishlist
  static const String wishlistStorageKey = 'guest_wishlist';
}

/// GuestCartItem - Guest cart item model
///
/// Minimal cart item data stored in guest storage.
/// Equivalent to Vue's guest cart item structure.
class GuestCartItem {
  final String id;
  final String? productId;
  final String? packageId;
  final int quantity;

  GuestCartItem({
    required this.id,
    this.productId,
    this.packageId,
    required this.quantity,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'package_id': packageId,
      'quantity': quantity,
    };
  }

  /// Create from JSON map
  factory GuestCartItem.fromJson(Map<String, dynamic> json) {
    return GuestCartItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String?,
      packageId: json['package_id'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

/// GuestWishlistItem - Guest wishlist item model
///
/// Minimal wishlist item data stored in guest storage.
/// Equivalent to Vue's guest wishlist item structure.
class GuestWishlistItem {
  final String id;
  final String? productId;
  final String? packageId;

  GuestWishlistItem({required this.id, this.productId, this.packageId});

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {'id': id, 'product_id': productId, 'package_id': packageId};
  }

  /// Create from JSON map
  factory GuestWishlistItem.fromJson(Map<String, dynamic> json) {
    return GuestWishlistItem(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String?,
      packageId: json['package_id'] as String?,
    );
  }
}

/// GuestStorageHelper - Utility for managing guest cart and wishlist
///
/// Equivalent to Vue's guestStorage.js utility file.
/// Manages guest cart and wishlist data in local storage.
/// This ensures data persists across app restarts for non-authenticated users.
class GuestStorageHelper {
  GuestStorageHelper._();

  /// Generate a unique guest ID
  ///
  /// Equivalent to Vue's `guest_${Date.now()}_${Math.random()}`
  static String _generateGuestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextDouble();
    return 'guest_${timestamp}_$random';
  }

  // ==================== Cart Methods ====================

  /// Get guest cart from storage
  ///
  /// Equivalent to Vue's getGuestCart() function.
  ///
  /// Returns list of guest cart items, or empty list on error
  ///
  /// Example:
  /// ```dart
  /// final cart = GuestStorageHelper.getGuestCart();
  /// ```
  static List<GuestCartItem> getGuestCart() {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return [];

      final cartJson = storage.getString(GuestStorageConstants.cartStorageKey);
      if (cartJson == null || cartJson.isEmpty) return [];

      final List<dynamic> cartList = jsonDecode(cartJson);
      return cartList
          .map((item) => GuestCartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      debugPrint('Error reading guest cart from storage: $error');
      return [];
    }
  }

  /// Save guest cart to storage
  ///
  /// Equivalent to Vue's saveGuestCart() function.
  ///
  /// [cart] - List of guest cart items to save
  ///
  /// Example:
  /// ```dart
  /// GuestStorageHelper.saveGuestCart(cart);
  /// ```
  static Future<void> saveGuestCart(List<GuestCartItem> cart) async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return;

      final cartJson = jsonEncode(cart.map((item) => item.toJson()).toList());
      await storage.setString(GuestStorageConstants.cartStorageKey, cartJson);
    } catch (error) {
      debugPrint('Error saving guest cart to storage: $error');
    }
  }

  /// Add item to guest cart in storage
  ///
  /// Equivalent to Vue's addToGuestCart() function.
  ///
  /// [item] - Item to add (must have product_id or package_id)
  /// Returns updated cart list
  ///
  /// Example:
  /// ```dart
  /// final cart = await GuestStorageHelper.addToGuestCart(
  ///   GuestCartItem(
  ///     id: 'item_1',
  ///     productId: 'product_123',
  ///     quantity: 1,
  ///   ),
  /// );
  /// ```
  static Future<List<GuestCartItem>> addToGuestCart(GuestCartItem item) async {
    final cart = getGuestCart();

    // Check if item already exists (by product_id or package_id)
    int existingIndex = -1;
    for (int i = 0; i < cart.length; i++) {
      final cartItem = cart[i];
      if (item.productId != null && cartItem.productId == item.productId) {
        existingIndex = i;
        break;
      }
      if (item.packageId != null && cartItem.packageId == item.packageId) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      // Update quantity if exists
      final existingItem = cart[existingIndex];
      cart[existingIndex] = GuestCartItem(
        id: existingItem.id,
        productId: existingItem.productId,
        packageId: existingItem.packageId,
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      // Add new item
      cart.add(
        GuestCartItem(
          id: item.id.isEmpty ? _generateGuestId() : item.id,
          productId: item.productId,
          packageId: item.packageId,
          quantity: item.quantity,
        ),
      );
    }

    await saveGuestCart(cart);
    return cart;
  }

  /// Update item quantity in guest cart
  ///
  /// Equivalent to Vue's updateGuestCartItem() function.
  ///
  /// [id] - Item ID to update
  /// [quantity] - New quantity (removes item if <= 0)
  /// Returns updated cart list
  ///
  /// Example:
  /// ```dart
  /// final cart = await GuestStorageHelper.updateGuestCartItem('item_1', 3);
  /// ```
  static Future<List<GuestCartItem>> updateGuestCartItem(
    String id,
    int quantity,
  ) async {
    final cart = getGuestCart();
    final itemIndex = cart.indexWhere((item) => item.id == id);

    if (itemIndex != -1) {
      if (quantity <= 0) {
        cart.removeAt(itemIndex);
      } else {
        final existingItem = cart[itemIndex];
        cart[itemIndex] = GuestCartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          packageId: existingItem.packageId,
          quantity: quantity,
        );
      }
      await saveGuestCart(cart);
    }

    return cart;
  }

  /// Remove item from guest cart
  ///
  /// Equivalent to Vue's removeFromGuestCart() function.
  ///
  /// [id] - Item ID to remove
  /// Returns updated cart list
  ///
  /// Example:
  /// ```dart
  /// final cart = await GuestStorageHelper.removeFromGuestCart('item_1');
  /// ```
  static Future<List<GuestCartItem>> removeFromGuestCart(String id) async {
    final cart = getGuestCart();
    final filtered = cart.where((item) => item.id != id).toList();
    await saveGuestCart(filtered);
    return filtered;
  }

  /// Clear guest cart
  ///
  /// Equivalent to Vue's clearGuestCart() function.
  ///
  /// Example:
  /// ```dart
  /// await GuestStorageHelper.clearGuestCart();
  /// ```
  static Future<void> clearGuestCart() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return;
      await storage.remove(GuestStorageConstants.cartStorageKey);
    } catch (error) {
      debugPrint('Error clearing guest cart: $error');
    }
  }

  // ==================== Wishlist Methods ====================

  /// Get guest wishlist from storage
  ///
  /// Equivalent to Vue's getGuestWishlist() function.
  ///
  /// Returns list of guest wishlist items, or empty list on error
  ///
  /// Example:
  /// ```dart
  /// final wishlist = GuestStorageHelper.getGuestWishlist();
  /// ```
  static List<GuestWishlistItem> getGuestWishlist() {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return [];

      final wishlistJson = storage.getString(
        GuestStorageConstants.wishlistStorageKey,
      );
      if (wishlistJson == null || wishlistJson.isEmpty) return [];

      final List<dynamic> wishlistList = jsonDecode(wishlistJson);
      return wishlistList
          .map(
            (item) => GuestWishlistItem.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (error) {
      debugPrint('Error reading guest wishlist from storage: $error');
      return [];
    }
  }

  /// Save guest wishlist to storage
  ///
  /// Equivalent to Vue's saveGuestWishlist() function.
  ///
  /// [wishlist] - List of guest wishlist items to save
  ///
  /// Example:
  /// ```dart
  /// GuestStorageHelper.saveGuestWishlist(wishlist);
  /// ```
  static Future<void> saveGuestWishlist(
    List<GuestWishlistItem> wishlist,
  ) async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return;

      final wishlistJson = jsonEncode(
        wishlist.map((item) => item.toJson()).toList(),
      );
      await storage.setString(
        GuestStorageConstants.wishlistStorageKey,
        wishlistJson,
      );
    } catch (error) {
      debugPrint('Error saving guest wishlist to storage: $error');
    }
  }

  /// Add item to guest wishlist in storage
  ///
  /// Equivalent to Vue's addToGuestWishlist() function.
  ///
  /// [item] - Item to add (must have product_id or package_id)
  /// Returns updated wishlist list
  ///
  /// Example:
  /// ```dart
  /// final wishlist = await GuestStorageHelper.addToGuestWishlist(
  ///   GuestWishlistItem(
  ///     id: 'item_1',
  ///     productId: 'product_123',
  ///   ),
  /// );
  /// ```
  static Future<List<GuestWishlistItem>> addToGuestWishlist(
    GuestWishlistItem item,
  ) async {
    final wishlist = getGuestWishlist();

    // Check if already exists
    bool exists = false;
    for (final wishlistItem in wishlist) {
      if (item.productId != null && wishlistItem.productId == item.productId) {
        exists = true;
        break;
      }
      if (item.packageId != null && wishlistItem.packageId == item.packageId) {
        exists = true;
        break;
      }
    }

    if (!exists) {
      wishlist.add(
        GuestWishlistItem(
          id: item.id.isEmpty ? _generateGuestId() : item.id,
          productId: item.productId,
          packageId: item.packageId,
        ),
      );
      await saveGuestWishlist(wishlist);
    }

    return wishlist;
  }

  /// Remove item from guest wishlist
  ///
  /// Equivalent to Vue's removeFromGuestWishlist() function.
  ///
  /// [productId] - Product ID to remove (optional)
  /// [packageId] - Package ID to remove (optional)
  /// Returns updated wishlist list
  ///
  /// Example:
  /// ```dart
  /// final wishlist = await GuestStorageHelper.removeFromGuestWishlist(
  ///   productId: 'product_123',
  /// );
  /// ```
  static Future<List<GuestWishlistItem>> removeFromGuestWishlist({
    String? productId,
    String? packageId,
  }) async {
    final wishlist = getGuestWishlist();
    final filtered = wishlist.where((item) {
      if (productId != null && item.productId == productId) return false;
      if (packageId != null && item.packageId == packageId) return false;
      return true;
    }).toList();
    await saveGuestWishlist(filtered);
    return filtered;
  }

  /// Check if item is in guest wishlist
  ///
  /// Equivalent to Vue's isInGuestWishlist() function.
  ///
  /// [productId] - Product ID to check (optional)
  /// [packageId] - Package ID to check (optional)
  /// Returns true if item exists in wishlist
  ///
  /// Example:
  /// ```dart
  /// final isWishlisted = GuestStorageHelper.isInGuestWishlist(
  ///   productId: 'product_123',
  /// );
  /// ```
  static bool isInGuestWishlist({String? productId, String? packageId}) {
    final wishlist = getGuestWishlist();
    return wishlist.any((item) {
      if (productId != null && item.productId == productId) return true;
      if (packageId != null && item.packageId == packageId) return true;
      return false;
    });
  }

  /// Clear guest wishlist
  ///
  /// Equivalent to Vue's clearGuestWishlist() function.
  ///
  /// Example:
  /// ```dart
  /// await GuestStorageHelper.clearGuestWishlist();
  /// ```
  static Future<void> clearGuestWishlist() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) return;
      await storage.remove(GuestStorageConstants.wishlistStorageKey);
    } catch (error) {
      debugPrint('Error clearing guest wishlist: $error');
    }
  }

  // ==================== Sync Methods ====================

  /// Sync guest cart with backend session
  ///
  /// Equivalent to Vue's syncGuestCartWithBackend() function.
  /// Merges localStorage data with backend session data.
  ///
  /// **Note**: This is a placeholder. Actual API implementation should be
  /// done in a separate service layer.
  ///
  /// Returns merged cart items from backend
  ///
  /// Example:
  /// ```dart
  /// final syncedCart = await GuestStorageHelper.syncGuestCartWithBackend();
  /// ```
  static Future<List<GuestCartItem>> syncGuestCartWithBackend() async {
    try {
      final localCart = getGuestCart();
      if (localCart.isEmpty) return [];

      // NOTE: Implement actual API call once backend is ready
      // Send localStorage cart to backend to merge with session
      // const response = await apiService.post('/cart/sync-guest', {
      //   items: localCart.map((item) => item.toJson()).toList(),
      // });
      // return response.data.items.map((item) => GuestCartItem.fromJson(item));

      // For now, return local cart
      return localCart;
    } catch (error) {
      debugPrint('Error syncing guest cart with backend: $error');
      return getGuestCart();
    }
  }

  /// Sync guest wishlist with backend session
  ///
  /// Equivalent to Vue's syncGuestWishlistWithBackend() function.
  ///
  /// **Note**: This is a placeholder. Actual API implementation should be
  /// done in a separate service layer.
  ///
  /// Returns merged wishlist items from backend
  ///
  /// Example:
  /// ```dart
  /// final syncedWishlist = await GuestStorageHelper.syncGuestWishlistWithBackend();
  /// ```
  static Future<List<GuestWishlistItem>> syncGuestWishlistWithBackend() async {
    try {
      final localWishlist = getGuestWishlist();
      if (localWishlist.isEmpty) return [];

      // NOTE: Implement actual API call once backend is ready
      // Send localStorage wishlist to backend to merge with session
      // const response = await apiService.post('/wishlist/sync-guest', {
      //   items: localWishlist.map((item) => item.toJson()).toList(),
      // });
      // return response.data.map((item) => GuestWishlistItem.fromJson(item));

      // For now, return local wishlist
      return localWishlist;
    } catch (error) {
      debugPrint('Error syncing guest wishlist with backend: $error');
      return getGuestWishlist();
    }
  }
}
