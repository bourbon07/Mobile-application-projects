/// App Store API - Abstracted API service interface
///
/// This file defines abstract interfaces for API calls that the app store
/// might need. Actual implementations should be provided separately.
///
/// This keeps the store clean and testable by abstracting backend calls.
library;

/// Abstract API service for product-related operations
abstract class ProductApiService {
  /// Update product search count
  /// This would typically make an API call to track product searches
  Future<void> updateProductSearchCount(String productId);
}

/// Abstract API service for cart operations
abstract class CartApiService {
  /// Sync cart with backend
  Future<void> syncCart(List<Map<String, dynamic>> cartItems);

  /// Get cart from backend
  Future<List<Map<String, dynamic>>> getCart();
}

/// Abstract API service for order operations
abstract class OrderApiService {
  /// Create order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData);

  /// Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders();
}

/// Abstract API service for wishlist operations
abstract class WishlistApiService {
  /// Sync wishlist with backend
  Future<void> syncWishlist(List<String> productIds);

  /// Get wishlist from backend
  Future<List<String>> getWishlist();
}

/// Abstract API service for chat operations
abstract class ChatApiService {
  /// Send chat message
  Future<void> sendMessage(Map<String, dynamic> messageData);

  /// Get chat messages
  Future<List<Map<String, dynamic>>> getMessages(String? conversationId);
}

/// Abstract API service for user operations
abstract class UserApiService {
  /// Get current user
  Future<Map<String, dynamic>?> getCurrentUser();

  /// Update user profile
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData);
}

/// Abstract API service for authentication operations
abstract class AuthApiService {
  /// Login with credentials
  /// Returns response with access_token and user
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials);

  /// Register new user
  /// Returns response with access_token and user
  Future<Map<String, dynamic>> register(Map<String, dynamic> data);

  /// Logout current user
  Future<void> logout();

  /// Fetch current user from server
  /// Returns user data, throws if user is blocked
  Future<Map<String, dynamic>> fetchUser();
}

/// Mock implementations for testing/development
///
/// These can be used during development or testing.
/// In production, replace with actual API implementations.

class MockProductApiService implements ProductApiService {
  @override
  Future<void> updateProductSearchCount(String productId) async {
    // Mock implementation - no actual API call
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

class MockCartApiService implements CartApiService {
  @override
  Future<void> syncCart(List<Map<String, dynamic>> cartItems) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<Map<String, dynamic>>> getCart() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }
}

class MockOrderApiService implements OrderApiService {
  @override
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': 'order_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      ...orderData,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }
}

class MockWishlistApiService implements WishlistApiService {
  @override
  Future<void> syncWishlist(List<String> productIds) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<String>> getWishlist() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }
}

class MockChatApiService implements ChatApiService {
  @override
  Future<void> sendMessage(Map<String, dynamic> messageData) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String? conversationId) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return [];
  }
}

class MockUserApiService implements UserApiService {
  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return null;
  }

  @override
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return userData;
  }
}

class MockAuthApiService implements AuthApiService {
  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'access_token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        'name': credentials['name'] ?? 'User',
        'email': credentials['email'] ?? 'user@example.com',
        'role': 'customer',
        'isBlocked': false,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'access_token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': {
        'id': '1',
        'name': data['name'] ?? 'User',
        'email': data['email'] ?? 'user@example.com',
        'role': 'customer',
        'isBlocked': false,
      },
    };
  }

  @override
  Future<void> logout() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<Map<String, dynamic>> fetchUser() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'id': '1',
      'name': 'User',
      'email': 'user@example.com',
      'role': 'customer',
      'isBlocked': false,
    };
  }
}


