library;

/// App Models - Data models for app store state
///
/// These models represent the state structure used in the app store.
/// They are serializable for persistence.

/// AppUser - User data model
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? role;
  final bool? isBlocked;
  final Map<String, dynamic>? additionalData;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.isBlocked,
    this.additionalData,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isBlocked': isBlocked,
      'additionalData': additionalData,
    };
  }

  /// Create from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      final s = v.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
      return null;
    }

    Map<String, dynamic>? parseMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final additional = <String, dynamic>{};
    final existingAdditional = parseMap(json['additionalData']);
    if (existingAdditional != null) {
      additional.addAll(existingAdditional);
    }

    // Capture common Laravel user fields (snake_case) so UI can access them.
    for (final key in const [
      'google_id',
      'avatar_url',
      'bio',
      'location',
      'phone',
      'is_private',
      'is_blocked',
      'blocked_at',
      'blocked_by',
      'email_verified_at',
      'profile_verified_at',
      'created_at',
      'updated_at',
      'status',
    ]) {
      if (json.containsKey(key) && !additional.containsKey(key)) {
        additional[key] = json[key];
      }
    }

    return AppUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: json['role']?.toString(),
      // Support both camelCase and snake_case
      isBlocked: parseBool(json['isBlocked'] ?? json['is_blocked']),
      additionalData: additional.isEmpty ? null : additional,
    );
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    bool? isBlocked,
    Map<String, dynamic>? additionalData,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

/// AppCartItem - Cart item model for app store
class AppCartItem {
  final String id;
  final int quantity;
  final String? productId;
  final String? packageId;
  final Map<String, dynamic>? itemData;

  const AppCartItem({
    required this.id,
    required this.quantity,
    this.productId,
    this.packageId,
    this.itemData,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'productId': productId,
      'packageId': packageId,
      'itemData': itemData,
    };
  }

  /// Create from JSON
  factory AppCartItem.fromJson(Map<String, dynamic> json) {
    return AppCartItem(
      id: (json['id'] ?? '').toString(),
      quantity: (json['quantity'] as num).toInt(),
      productId: json['productId']?.toString(),
      packageId: json['packageId']?.toString(),
      itemData: json['itemData'] is Map
          ? Map<String, dynamic>.from(json['itemData'] as Map)
          : null,
    );
  }

  /// Create a copy with updated fields
  AppCartItem copyWith({
    String? id,
    int? quantity,
    String? productId,
    String? packageId,
    Map<String, dynamic>? itemData,
  }) {
    return AppCartItem(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      productId: productId ?? this.productId,
      packageId: packageId ?? this.packageId,
      itemData: itemData ?? this.itemData,
    );
  }
}

/// AppOrder - Order data model
class AppOrder {
  final String id;
  final DateTime createdAt;
  final String status;
  final double totalPrice;
  final List<AppCartItem> items;
  final Map<String, dynamic>? orderData;

  const AppOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalPrice,
    required this.items,
    this.orderData,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'totalPrice': totalPrice,
      'items': items.map((item) => item.toJson()).toList(),
      'orderData': orderData,
    };
  }

  /// Create from JSON
  factory AppOrder.fromJson(Map<String, dynamic> json) {
    return AppOrder(
      id: (json['id'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: (json['status'] ?? '').toString(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => AppCartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      orderData: json['orderData'] is Map
          ? Map<String, dynamic>.from(json['orderData'] as Map)
          : null,
    );
  }
}

/// AppChatMessage - Chat message model
class AppChatMessage {
  final String id;
  final String message;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? messageData;

  const AppChatMessage({
    required this.id,
    required this.message,
    this.userId,
    required this.timestamp,
    this.messageData,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'messageData': messageData,
    };
  }

  /// Create from JSON
  factory AppChatMessage.fromJson(Map<String, dynamic> json) {
    return AppChatMessage(
      id: (json['id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      userId: json['userId']?.toString(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      messageData: json['messageData'] is Map
          ? Map<String, dynamic>.from(json['messageData'] as Map)
          : null,
    );
  }
}

/// AppTheme - Theme enum
enum AppTheme {
  light,
  dark;

  String get value => name;

  static AppTheme fromString(String value) {
    return AppTheme.values.firstWhere(
      (theme) => theme.value == value,
      orElse: () => AppTheme.light,
    );
  }
}


