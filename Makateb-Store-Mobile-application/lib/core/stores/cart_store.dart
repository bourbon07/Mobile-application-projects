import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_services/cart_api_service.dart';
import '../widgets/product_card.dart' show ProductData;
import '../widgets/package_card.dart' show PackageData;

/// Cart item data model
class CartItem {
  final String id;
  final String? productId;
  final String? packageId;
  final int quantity;
  final ProductData? product;
  final PackageData? package;

  const CartItem({
    required this.id,
    this.productId,
    this.packageId,
    required this.quantity,
    this.product,
    this.package,
  });
}

/// Cart state
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  const CartState({this.items = const [], this.isLoading = false, this.error});

  CartState copyWith({List<CartItem>? items, bool? isLoading, String? error}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

/// Cart store notifier
class CartStore extends StateNotifier<CartState> {
  final LaravelCartApiService _cartApi;

  CartStore(this._cartApi) : super(const CartState()) {
    loadCart();
  }

  /// Load cart from API
  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (kDebugMode) {
        debugPrint('[CartStore] Loading cart from API...');
      }
      final cartRaw = await _cartApi.fetchCart();
      if (kDebugMode) {
        debugPrint('[CartStore] Received ${cartRaw.length} raw items from API');
        if (cartRaw.isNotEmpty) {
          debugPrint('[CartStore] First item structure: ${cartRaw.first}');
        }
      }
      final parsed = <CartItem>[];

      for (final item in cartRaw) {
        if (item is! Map) {
          if (kDebugMode) {
            debugPrint('[CartStore] Skipping non-map item: $item');
          }
          continue;
        }
        final map = Map<String, dynamic>.from(item);

        final id = (map['id'] ?? map['cart_id'] ?? '').toString();

        var productId = (map['product_id'] ?? map['productId'])?.toString();
        var packageId = (map['package_id'] ?? map['packageId'])?.toString();

        // Try nested objects if direct keys missing
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

        final quantity = map['quantity'] is int
            ? map['quantity'] as int
            : int.tryParse(map['quantity']?.toString() ?? '') ?? 1;

        ProductData? product;
        PackageData? package;

        // Parse product
        if (productId != null && productId.isNotEmpty) {
          final productMap = map['product'];
          if (productMap is Map) {
            product = _parseProduct(Map<String, dynamic>.from(productMap));
          } else {
            if (kDebugMode) {
              debugPrint(
                '[CartStore] Product data missing for product_id: $productId',
              );
              debugPrint(
                '[CartStore] Available keys in item: ${map.keys.toList()}',
              );
              debugPrint('[CartStore] Full item data: $map');
            }
            // Create a minimal product if we have at least an ID
            product = ProductData(
              id: productId,
              name: 'Product $productId',
              description: null,
              price: 0.0,
              imageUrl: null,
              stock: null,
            );
          }
        }

        // Parse package
        if (packageId != null && packageId.isNotEmpty) {
          final packageMap = map['package'];
          if (packageMap is Map) {
            package = _parsePackage(Map<String, dynamic>.from(packageMap));
          } else {
            if (kDebugMode) {
              debugPrint(
                '[CartStore] Package data missing for package_id: $packageId',
              );
              debugPrint(
                '[CartStore] Available keys in item: ${map.keys.toList()}',
              );
              debugPrint('[CartStore] Full item data: $map');
            }
            // Create a minimal package if we have at least an ID
            package = PackageData(
              id: packageId,
              name: 'Package $packageId',
              description: null,
              price: 0.0,
              imageUrl: null,
              productsCount: 0,
            );
          }
        }

        // Always add item, even if product/package data is minimal
        if (productId != null || packageId != null) {
          parsed.add(
            CartItem(
              id: id.isNotEmpty
                  ? id
                  : 'item_${productId ?? packageId}_${DateTime.now().millisecondsSinceEpoch}',
              productId: productId,
              packageId: packageId,
              quantity: quantity,
              product: product,
              package: package,
            ),
          );
          if (kDebugMode) {
            debugPrint(
              '[CartStore] Added cart item: id=$id, productId=$productId, packageId=$packageId, quantity=$quantity',
            );
          }
        } else if (kDebugMode) {
          debugPrint(
            '[CartStore] Skipping item $id: no product_id or package_id',
          );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[CartStore] Loaded ${parsed.length} items from API (out of ${cartRaw.length} raw items)',
        );
        if (parsed.isEmpty && cartRaw.isNotEmpty) {
          debugPrint(
            '[CartStore] WARNING: No items parsed! Raw cart data: $cartRaw',
          );
        }
      }

      state = state.copyWith(items: parsed, isLoading: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error loading cart: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Helper to process raw list of items and update state
  void _updateStateFromRawList(List<dynamic> cartRaw) {
    final parsed = <CartItem>[];

    for (final item in cartRaw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final id = (map['id'] ?? map['cart_id'] ?? '').toString();

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

      final quantity = map['quantity'] is int
          ? map['quantity'] as int
          : int.tryParse(map['quantity']?.toString() ?? '') ?? 1;

      ProductData? product;
      PackageData? package;

      if (productId != null && productId.isNotEmpty) {
        final productMap = map['product'];
        if (productMap is Map) {
          product = _parseProduct(Map<String, dynamic>.from(productMap));
        } else {
          // Minimal product
          product = ProductData(
            id: productId,
            name: 'Product $productId',
            description: null,
            price: 0.0,
            imageUrl: null,
            stock: null,
          );
        }
      }

      if (packageId != null && packageId.isNotEmpty) {
        final packageMap = map['package'];
        if (packageMap is Map) {
          package = _parsePackage(Map<String, dynamic>.from(packageMap));
        } else {
          // Minimal package
          package = PackageData(
            id: packageId,
            name: 'Package $packageId',
            description: null,
            price: 0.0,
            imageUrl: null,
            productsCount: 0,
          );
        }
      }

      if (productId != null || packageId != null) {
        parsed.add(
          CartItem(
            id: id.isNotEmpty
                ? id
                : 'item_${productId ?? packageId}_${DateTime.now().millisecondsSinceEpoch}',
            productId: productId,
            packageId: packageId,
            quantity: quantity,
            product: product,
            package: package,
          ),
        );
      }
    }
    state = state.copyWith(items: parsed, isLoading: false);
  }

  ProductData _parseProduct(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString();
    final priceStr = map['price']?.toString();
    final price = double.tryParse(priceStr ?? '') ?? 0.0;
    final stock = map['stock'] is int
        ? map['stock'] as int
        : int.tryParse(map['stock']?.toString() ?? '');

    final imageUrl = map['image_url']?.toString();
    final imageUrls = map['image_urls'];
    final resolvedImageUrl = (imageUrl != null && imageUrl.isNotEmpty)
        ? imageUrl
        : (imageUrls is List && imageUrls.isNotEmpty)
        ? imageUrls.first?.toString()
        : null;

    return ProductData(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: map['description']?.toString(),
      price: price,
      imageUrl: resolvedImageUrl,
      stock: stock,
    );
  }

  PackageData _parsePackage(Map<String, dynamic> map) {
    final id = (map['id'] ?? '').toString();
    final priceStr = map['price']?.toString();
    final price = double.tryParse(priceStr ?? '') ?? 0.0;
    final imageUrl = map['image_url']?.toString();
    final count = map['products_count'] is int
        ? map['products_count'] as int
        : int.tryParse(map['products_count']?.toString() ?? '') ?? 0;

    return PackageData(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: map['description']?.toString(),
      price: price,
      imageUrl: imageUrl,
      productsCount: count,
    );
  }

  /// Add product to cart
  Future<bool> addProduct(String productId, {int quantity = 1}) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[CartStore] Adding product $productId to cart (quantity: $quantity)',
        );
      }
      final response = await _cartApi.addProductToCart(
        productId,
        quantity: quantity,
      );

      // Check if response has items to update state directly
      if (response.containsKey('items') && response['items'] is List) {
        if (kDebugMode) {
          debugPrint('[CartStore] Updating cart from add response');
        }
        final itemsList = response['items'] as List;
        _updateStateFromRawList(itemsList);
        return true;
      }

      if (kDebugMode) {
        debugPrint('[CartStore] Product added successfully, reloading cart...');
      }
      await loadCart();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error adding product: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Add package to cart
  Future<bool> addPackage(String packageId, {int quantity = 1}) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[CartStore] Adding package $packageId to cart (quantity: $quantity)',
        );
      }
      final response = await _cartApi.addPackageToCart(
        packageId,
        quantity: quantity,
      );

      // Check if response has items to update state directly
      if (response.containsKey('items') && response['items'] is List) {
        if (kDebugMode) {
          debugPrint('[CartStore] Updating cart from add package response');
        }
        final itemsList = response['items'] as List;
        _updateStateFromRawList(itemsList);
        return true;
      }

      if (kDebugMode) {
        debugPrint('[CartStore] Package added successfully, reloading cart...');
      }
      await loadCart();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error adding package: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update quantity
  Future<bool> updateQuantity(String itemId, int quantity) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[CartStore] Updating quantity for item $itemId to $quantity',
        );
      }
      await _cartApi.updateQuantity(itemId, quantity);
      await loadCart();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error updating quantity: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove item
  Future<bool> removeItem(String itemId) async {
    try {
      if (kDebugMode) {
        debugPrint('[CartStore] Removing item $itemId from cart');
      }
      await _cartApi.removeFromCart(itemId);
      await loadCart();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error removing item: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear cart
  Future<bool> clear() async {
    try {
      if (kDebugMode) {
        debugPrint('[CartStore] Clearing cart');
      }
      await _cartApi.clearCart();
      await loadCart();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error clearing cart: $e');
      }
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sync guest cart items to server (call after login)
  Future<void> syncGuest() async {
    try {
      if (state.items.isEmpty) return;

      final syncItems = state.items
          .map(
            (item) => {
              'product_id': item.productId,
              'package_id': item.packageId,
              'quantity': item.quantity,
            },
          )
          .toList();

      await _cartApi.syncGuest(syncItems);
      await loadCart();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CartStore] Error syncing guest cart: $e');
      }
    }
  }
}

/// Cart store provider
final cartStoreProvider = StateNotifierProvider<CartStore, CartState>((ref) {
  return CartStore(LaravelCartApiService());
});

/// Cart items provider
final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartStoreProvider).items;
});

/// Cart count provider
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartStoreProvider).totalQuantity;
});
