import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';

/// AppState - State class for app store
///
/// Contains all the state managed by the app store.
/// Equivalent to Vue Pinia store state.
class AppState {
  final AppUser? user;
  final List<AppCartItem> cart;
  final List<String> wishlist;
  final List<AppOrder> orders;
  final AppTheme theme;
  final List<AppChatMessage> chatMessages;
  final String searchQuery;
  final String currentPage;
  final String selectedId;

  const AppState({
    this.user,
    this.cart = const [],
    this.wishlist = const [],
    this.orders = const [],
    this.theme = AppTheme.light,
    this.chatMessages = const [],
    this.searchQuery = '',
    this.currentPage = 'home',
    this.selectedId = '',
  });

  /// Create a copy with updated fields
  AppState copyWith({
    AppUser? user,
    List<AppCartItem>? cart,
    List<String>? wishlist,
    List<AppOrder>? orders,
    AppTheme? theme,
    List<AppChatMessage>? chatMessages,
    String? searchQuery,
    String? currentPage,
    String? selectedId,
  }) {
    return AppState(
      user: user ?? this.user,
      cart: cart ?? this.cart,
      wishlist: wishlist ?? this.wishlist,
      orders: orders ?? this.orders,
      theme: theme ?? this.theme,
      chatMessages: chatMessages ?? this.chatMessages,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      selectedId: selectedId ?? this.selectedId,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'cart': cart.map((item) => item.toJson()).toList(),
      'wishlist': wishlist,
      'orders': orders.map((order) => order.toJson()).toList(),
      'theme': theme.value,
      'chatMessages': chatMessages.map((msg) => msg.toJson()).toList(),
      'searchQuery': searchQuery,
      'currentPage': currentPage,
      'selectedId': selectedId,
    };
  }

  /// Create from JSON
  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      user: json['user'] != null
          ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      cart: (json['cart'] as List<dynamic>?)
              ?.map((item) =>
                  AppCartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      wishlist: (json['wishlist'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      orders: (json['orders'] as List<dynamic>?)
              ?.map((order) =>
                  AppOrder.fromJson(order as Map<String, dynamic>))
              .toList() ??
          [],
      theme: AppTheme.fromString(json['theme'] as String? ?? 'light'),
      chatMessages: (json['chatMessages'] as List<dynamic>?)
              ?.map((msg) =>
                  AppChatMessage.fromJson(msg as Map<String, dynamic>))
              .toList() ??
          [],
      searchQuery: json['searchQuery'] as String? ?? '',
      currentPage: json['currentPage'] as String? ?? 'home',
      selectedId: json['selectedId'] as String? ?? '',
    );
  }
}

/// AppStoreNotifier - StateNotifier for app store
///
/// Equivalent to Vue Pinia store actions and state management.
/// Handles all state mutations and persistence.
class AppStoreNotifier extends StateNotifier<AppState> {
  AppStoreNotifier() : super(const AppState()) {
    _loadFromStorage();
  }

  /// Storage keys
  static const String _keyUser = 'app_user';
  static const String _keyCart = 'app_cart';
  static const String _keyWishlist = 'app_wishlist';
  static const String _keyOrders = 'app_orders';
  static const String _keyTheme = 'app_theme';

  /// Load state from storage
  /// Equivalent to Vue's loadFromStorage()
  Future<void> _loadFromStorage() async {
    try {
      final storage = StorageService.instance;
      if (!storage.isInitialized) {
        await storage.initialize();
      }

      // Load user
      final savedUser = storage.getString(_keyUser);
      AppUser? user;
      if (savedUser != null) {
        try {
          user = AppUser.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Error loading user from storage: $e');
        }
      }

      // Load cart
      final savedCart = storage.getString(_keyCart);
      List<AppCartItem> cart = [];
      if (savedCart != null) {
        try {
          final cartList = jsonDecode(savedCart) as List<dynamic>;
          cart = cartList
              .map((item) =>
                  AppCartItem.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error loading cart from storage: $e');
        }
      }

      // Load wishlist
      final savedWishlist = storage.getString(_keyWishlist);
      List<String> wishlist = [];
      if (savedWishlist != null) {
        try {
          wishlist = (jsonDecode(savedWishlist) as List<dynamic>)
              .map((item) => item as String)
              .toList();
        } catch (e) {
          debugPrint('Error loading wishlist from storage: $e');
        }
      }

      // Load orders
      final savedOrders = storage.getString(_keyOrders);
      List<AppOrder> orders = [];
      if (savedOrders != null) {
        try {
          final ordersList = jsonDecode(savedOrders) as List<dynamic>;
          orders = ordersList
              .map((order) =>
                  AppOrder.fromJson(order as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Error loading orders from storage: $e');
        }
      }

      // Load theme
      final savedTheme = storage.getString(_keyTheme);
      final theme = savedTheme != null
          ? AppTheme.fromString(savedTheme)
          : AppTheme.light;

      // Update state
      state = state.copyWith(
        user: user,
        cart: cart,
        wishlist: wishlist,
        orders: orders,
        theme: theme,
      );
    } catch (e) {
      debugPrint('Error loading from storage: $e');
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

  /// Save cart to storage
  Future<void> _saveCart(List<AppCartItem> cart) async {
    final storage = StorageService.instance;
    final cartJson = jsonEncode(cart.map((item) => item.toJson()).toList());
    await storage.setString(_keyCart, cartJson);
  }

  /// Save wishlist to storage
  Future<void> _saveWishlist(List<String> wishlist) async {
    final storage = StorageService.instance;
    await storage.setString(_keyWishlist, jsonEncode(wishlist));
  }

  /// Save orders to storage
  Future<void> _saveOrders(List<AppOrder> orders) async {
    final storage = StorageService.instance;
    final ordersJson = jsonEncode(orders.map((order) => order.toJson()).toList());
    await storage.setString(_keyOrders, ordersJson);
  }

  /// Save theme to storage
  Future<void> _saveTheme(AppTheme theme) async {
    final storage = StorageService.instance;
    await storage.setString(_keyTheme, theme.value);
  }

  // ==================== Actions ====================

  /// Set user
  /// Equivalent to Vue's setUser()
  Future<void> setUser(AppUser? newUser) async {
    state = state.copyWith(user: newUser);
    await _saveUser(newUser);
  }

  /// Add item to cart
  /// Equivalent to Vue's addToCart()
  Future<void> addToCart(AppCartItem item) async {
    final cart = List<AppCartItem>.from(state.cart);
    final existingIndex = cart.indexWhere((i) => i.id == item.id);

    if (existingIndex > -1) {
      // Update quantity if item exists
      final existing = cart[existingIndex];
      cart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      // Add new item
      cart.add(item);
    }

    state = state.copyWith(cart: cart);
    await _saveCart(cart);
  }

  /// Remove item from cart
  /// Equivalent to Vue's removeFromCart()
  Future<void> removeFromCart(String id) async {
    final cart = state.cart.where((item) => item.id != id).toList();
    state = state.copyWith(cart: cart);
    await _saveCart(cart);
  }

  /// Update cart item quantity
  /// Equivalent to Vue's updateCartQuantity()
  Future<void> updateCartQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(id);
      return;
    }

    final cart = List<AppCartItem>.from(state.cart);
    final index = cart.indexWhere((item) => item.id == id);

    if (index > -1) {
      cart[index] = cart[index].copyWith(quantity: quantity);
      state = state.copyWith(cart: cart);
      await _saveCart(cart);
    }
  }

  /// Clear cart
  /// Equivalent to Vue's clearCart()
  Future<void> clearCart() async {
    state = state.copyWith(cart: []);
    await _saveCart([]);
  }

  /// Toggle wishlist item
  /// Equivalent to Vue's toggleWishlist()
  Future<void> toggleWishlist(String productId) async {
    final wishlist = List<String>.from(state.wishlist);
    final index = wishlist.indexOf(productId);

    if (index > -1) {
      wishlist.removeAt(index);
    } else {
      wishlist.add(productId);
    }

    state = state.copyWith(wishlist: wishlist);
    await _saveWishlist(wishlist);
  }

  /// Add order
  /// Equivalent to Vue's addOrder()
  Future<void> addOrder(AppOrder order) async {
    final orders = [order, ...state.orders];
    state = state.copyWith(orders: orders);
    await _saveOrders(orders);
  }

  /// Toggle theme
  /// Equivalent to Vue's toggleTheme()
  Future<void> toggleTheme() async {
    final newTheme = state.theme == AppTheme.light
        ? AppTheme.dark
        : AppTheme.light;
    state = state.copyWith(theme: newTheme);
    await _saveTheme(newTheme);
  }

  /// Add chat message
  /// Equivalent to Vue's addChatMessage()
  void addChatMessage(AppChatMessage message) {
    final messages = [...state.chatMessages, message];
    state = state.copyWith(chatMessages: messages);
    // Note: Chat messages are not persisted by default
    // Uncomment if persistence is needed:
    // await _saveChatMessages(messages);
  }

  /// Set search query
  /// Equivalent to Vue's setSearchQuery()
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Update product search count
  /// Equivalent to Vue's updateProductSearchCount()
  /// This is abstracted - actual API call would be made here
  Future<void> updateProductSearchCount(String productId) async {
    // Abstracted API call - no implementation
    // In a real app, this would call an API service
    debugPrint('Search count updated for product: $productId');
    // Example: await apiService.updateProductSearchCount(productId);
  }

  /// Navigate
  /// Equivalent to Vue's navigate()
  void navigate(String page, {String? id}) {
    if (page == 'logout') {
      setUser(null);
      state = state.copyWith(currentPage: 'home', selectedId: '');
      return;
    }

    state = state.copyWith(
      currentPage: page,
      selectedId: id ?? '',
    );
  }
}

/// AppStoreProvider - Riverpod provider for app store
///
/// This is the main provider that exposes the app store state and actions.
final appStoreProvider = StateNotifierProvider<AppStoreNotifier, AppState>(
  (ref) => AppStoreNotifier(),
);

/// Computed/Selector Providers
///
/// These providers compute derived values from the app store state.
/// Equivalent to Vue's computed properties.

/// Cart count provider
/// Equivalent to Vue's cartCount computed
final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(appStoreProvider).cart;
  return cart.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );
});

/// User provider (nullable)
final userProvider = Provider<AppUser?>((ref) {
  return ref.watch(appStoreProvider).user;
});

/// Cart provider
final cartProvider = Provider<List<AppCartItem>>((ref) {
  return ref.watch(appStoreProvider).cart;
});

/// Wishlist provider
final wishlistProvider = Provider<List<String>>((ref) {
  return ref.watch(appStoreProvider).wishlist;
});

/// Orders provider
final ordersProvider = Provider<List<AppOrder>>((ref) {
  return ref.watch(appStoreProvider).orders;
});

/// Theme provider
final themeProvider = Provider<AppTheme>((ref) {
  return ref.watch(appStoreProvider).theme;
});

/// Chat messages provider
final chatMessagesProvider = Provider<List<AppChatMessage>>((ref) {
  return ref.watch(appStoreProvider).chatMessages;
});

/// Search query provider
final searchQueryProvider = Provider<String>((ref) {
  return ref.watch(appStoreProvider).searchQuery;
});

/// Current page provider
final currentPageProvider = Provider<String>((ref) {
  return ref.watch(appStoreProvider).currentPage;
});

/// Selected ID provider
final selectedIdProvider = Provider<String>((ref) {
  return ref.watch(appStoreProvider).selectedId;
});

/// Is wishlisted provider
/// Helper to check if a product is in wishlist
final isWishlistedProvider = Provider.family<bool, String>((ref, productId) {
  final wishlist = ref.watch(wishlistProvider);
  return wishlist.contains(productId);
});



