import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_services/wishlist_api_service.dart';

/// Wishlist item data model
class WishlistItemData {
  final String id;
  final String? productId;
  final String? packageId;
  final WishlistProductData? product;
  final WishlistPackageData? package;

  const WishlistItemData({
    required this.id,
    this.productId,
    this.packageId,
    this.product,
    this.package,
  });
}

/// Wishlist product data model
class WishlistProductData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? stock;

  const WishlistProductData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.stock,
  });
}

/// Wishlist package data model
class WishlistPackageData {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;

  const WishlistPackageData({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
  });
}

/// Wishlist state
class WishlistState {
  final List<WishlistItemData> items;
  final bool isLoading;
  final String? error;

  const WishlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  WishlistState copyWith({
    List<WishlistItemData>? items,
    bool? isLoading,
    String? error,
  }) {
    return WishlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get itemCount => items.length;
}

/// Wishlist store notifier
class WishlistStore extends StateNotifier<WishlistState> {
  final LaravelWishlistApiService _wishlistApi;

  WishlistStore(this._wishlistApi) : super(const WishlistState()) {
    loadWishlist();
  }

  /// Load wishlist from API
  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Loading wishlist from API...');
      }
      final wishlistRaw = await _wishlistApi.fetchWishlist();

      // Debug raw response
      if (kDebugMode) {
        debugPrint(
          '[WishlistStore] Raw response length: ${wishlistRaw.length}',
        );
        if (wishlistRaw.isNotEmpty) {
          debugPrint(
            '[WishlistStore] First raw item keys: ${(wishlistRaw.first is Map) ? (wishlistRaw.first as Map).keys.toList() : "not a map"}',
          );
        }
      }

      final parsed = <WishlistItemData>[];

      for (final item in wishlistRaw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        // Flexible ID parsing
        final id = (map['id'] ?? map['wishlist_id'] ?? '').toString();

        // Flexible Product/Package ID parsing
        // 1. Try direct keys
        var productId = (map['product_id'] ?? map['productId'])?.toString();
        var packageId = (map['package_id'] ?? map['packageId'])?.toString();

        // 2. Try nested objects if direct keys missing
        if (productId == null &&
            map['product'] != null &&
            map['product'] is Map) {
          productId = map['product']['id']?.toString();
        }
        if (packageId == null &&
            map['package'] != null &&
            map['package'] is Map) {
          packageId = map['package']['id']?.toString();
        }

        WishlistProductData? product;
        WishlistPackageData? package;

        // Parse product data
        if (productId != null) {
          final productMap = map['product'];
          if (productMap is Map) {
            product = _parseProduct(Map<String, dynamic>.from(productMap));
          } else {
            // Minimal product from ID if data missing
            product = WishlistProductData(
              id: productId,
              name: 'Product $productId',
              price: 0.0,
            );
          }
        }

        // Parse package data
        if (packageId != null) {
          final packageMap = map['package'];
          if (packageMap is Map) {
            package = _parsePackage(Map<String, dynamic>.from(packageMap));
          } else {
            // Minimal package from ID if data missing
            package = WishlistPackageData(
              id: packageId,
              name: 'Package $packageId',
              price: 0.0,
            );
          }
        }

        // Add if we have at least one valid item reference
        if (product != null || package != null) {
          parsed.add(
            WishlistItemData(
              id: id.isNotEmpty
                  ? id
                  : DateTime.now().millisecondsSinceEpoch
                        .toString(), // Fallback ID
              productId: productId,
              packageId: packageId,
              product: product,
              package: package,
            ),
          );
        }
      }

      state = state.copyWith(items: parsed, isLoading: false);

      if (kDebugMode) {
        debugPrint(
          '[WishlistStore] Successfully parsed ${parsed.length} items',
        );
      }
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error loading wishlist: $e');
        debugPrint(stack.toString());
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Helper to update state from raw list
  void _updateStateFromRawList(List<dynamic> wishlistRaw) {
    final parsed = <WishlistItemData>[];

    for (final item in wishlistRaw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final id = (map['id'] ?? map['wishlist_id'] ?? '').toString();

      var productId = (map['product_id'] ?? map['productId'])?.toString();
      var packageId = (map['package_id'] ?? map['packageId'])?.toString();

      if (productId == null &&
          map['product'] != null &&
          map['product'] is Map) {
        productId = map['product']['id']?.toString();
      }
      if (packageId == null &&
          map['package'] != null &&
          map['package'] is Map) {
        packageId = map['package']['id']?.toString();
      }

      WishlistProductData? product;
      WishlistPackageData? package;

      if (productId != null) {
        final productMap = map['product'];
        if (productMap is Map) {
          product = _parseProduct(Map<String, dynamic>.from(productMap));
        } else {
          product = WishlistProductData(
            id: productId,
            name: 'Product $productId',
            price: 0.0,
          );
        }
      }

      if (packageId != null) {
        final packageMap = map['package'];
        if (packageMap is Map) {
          package = _parsePackage(Map<String, dynamic>.from(packageMap));
        } else {
          package = WishlistPackageData(
            id: packageId,
            name: 'Package $packageId',
            price: 0.0,
          );
        }
      }

      if (product != null || package != null) {
        parsed.add(
          WishlistItemData(
            id: id.isNotEmpty
                ? id
                : DateTime.now().millisecondsSinceEpoch.toString(),
            productId: productId,
            packageId: packageId,
            product: product,
            package: package,
          ),
        );
      }
    }
    state = state.copyWith(items: parsed, isLoading: false);
  }

  WishlistProductData _parseProduct(Map<String, dynamic> map) {
    // Handle both string and int for ID
    final id = map['id']?.toString() ?? '';

    // Handle price as string, double, or int
    double price = 0.0;
    if (map['price'] != null) {
      price = double.tryParse(map['price'].toString()) ?? 0.0;
    }

    // Handle stock
    int? stock;
    if (map['stock'] != null) {
      stock = int.tryParse(map['stock'].toString());
    }

    // Handle images
    String? imageUrl = map['image_url']?.toString();
    if (imageUrl == null &&
        map['images'] is List &&
        (map['images'] as List).isNotEmpty) {
      imageUrl = (map['images'] as List).first['url']?.toString();
    }

    return WishlistProductData(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      price: price,
      imageUrl: imageUrl,
      stock: stock,
    );
  }

  WishlistPackageData _parsePackage(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';

    double price = 0.0;
    if (map['price'] != null) {
      price = double.tryParse(map['price'].toString()) ?? 0.0;
    }

    return WishlistPackageData(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      price: price,
      imageUrl: map['image_url']?.toString(),
    );
  }

  /// Add product to wishlist
  Future<bool> addProduct(String productId) async {
    try {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Adding product $productId to wishlist');
      }
      final response = await _wishlistApi.addProductToWishlist(productId);

      if (response.containsKey('items') && response['items'] is List) {
        if (kDebugMode) {
          debugPrint('[WishlistStore] Updating wishlist from add response');
        }
        final itemsList = response['items'] as List;
        _updateStateFromRawList(itemsList);
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '[WishlistStore] Product added successfully, reloading wishlist...',
        );
      }
      await loadWishlist();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error adding product: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add package to wishlist
  Future<bool> addPackage(String packageId) async {
    try {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Adding package $packageId to wishlist');
      }
      final response = await _wishlistApi.addPackageToWishlist(packageId);

      if (response.containsKey('items') && response['items'] is List) {
        if (kDebugMode) {
          debugPrint(
            '[WishlistStore] Updating wishlist from add package response',
          );
        }
        final itemsList = response['items'] as List;
        _updateStateFromRawList(itemsList);
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '[WishlistStore] Package added successfully, reloading wishlist...',
        );
      }
      await loadWishlist();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error adding package: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeProduct(String productId) async {
    try {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Removing product $productId from wishlist');
      }
      await _wishlistApi.removeProductFromWishlist(productId);
      await loadWishlist();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error removing product: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove package from wishlist
  Future<bool> removePackage(String packageId) async {
    try {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Removing package $packageId from wishlist');
      }
      await _wishlistApi.removePackageFromWishlist(packageId);
      await loadWishlist();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error removing package: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Check if product is in wishlist (synchronous, from current state)
  bool isProductInWishlistSync(String productId) {
    return state.items.any((item) => item.productId == productId);
  }

  /// Check if package is in wishlist (synchronous, from current state)
  bool isPackageInWishlistSync(String packageId) {
    return state.items.any((item) => item.packageId == packageId);
  }

  /// Toggle product in wishlist
  Future<bool> toggleProduct(String productId) async {
    final isInWishlist = isProductInWishlistSync(productId);
    if (isInWishlist) {
      return await removeProduct(productId);
    } else {
      return await addProduct(productId);
    }
  }

  /// Toggle package in wishlist
  Future<bool> togglePackage(String packageId) async {
    final isInWishlist = isPackageInWishlistSync(packageId);
    if (isInWishlist) {
      return await removePackage(packageId);
    } else {
      return await addPackage(packageId);
    }
  }

  /// Check if product is in wishlist (async, fetches if needed)
  Future<bool> isProductInWishlist(String productId) async {
    try {
      // If we already have items, check locally first
      if (state.items.isNotEmpty) {
        return isProductInWishlistSync(productId);
      }
      return await _wishlistApi.isProductInWishlist(productId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error checking product: $e');
      }
      return false;
    }
  }

  /// Check if package is in wishlist (async, fetches if needed)
  Future<bool> isPackageInWishlist(String packageId) async {
    try {
      // If we already have items, check locally first
      if (state.items.isNotEmpty) {
        return isPackageInWishlistSync(packageId);
      }
      return await _wishlistApi.isPackageInWishlist(packageId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error checking package: $e');
      }
      return false;
    }
  }

  /// Sync guest wishlist items to server (call after login)
  Future<void> syncGuest() async {
    try {
      if (state.items.isEmpty) return;

      final syncItems = state.items
          .map(
            (item) => {
              'product_id': item.productId,
              'package_id': item.packageId,
            },
          )
          .toList();

      await _wishlistApi.syncGuest(syncItems);
      await loadWishlist();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WishlistStore] Error syncing guest wishlist: $e');
      }
    }
  }
}

/// Wishlist store provider
final wishlistStoreProvider =
    StateNotifierProvider<WishlistStore, WishlistState>((ref) {
      return WishlistStore(LaravelWishlistApiService());
    });

/// Wishlist items provider
final wishlistItemsProvider = Provider<List<WishlistItemData>>((ref) {
  return ref.watch(wishlistStoreProvider).items;
});

/// Wishlist count provider
final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistStoreProvider).itemCount;
});
