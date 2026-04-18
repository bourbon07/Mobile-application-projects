import 'package:flutter/foundation.dart';
import '../api_client.dart';

/// LaravelOrderApiService
///
/// API service for order operations (create, history, etc.).
class LaravelOrderApiService {
  LaravelOrderApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetch user order history.
  Future<List<dynamic>> fetchOrders() async {
    try {
      if (kDebugMode) {
        debugPrint('[OrderAPI] Fetching orders from /orders endpoint...');
      }

      final res = await _api.getJson('/orders');

      if (kDebugMode) {
        debugPrint('[OrderAPI] Response type: ${res.runtimeType}');
        debugPrint('[OrderAPI] Response: $res');
      }

      // Handle ResourceCollection format {data: [...]}
      if (res is Map && res.containsKey('data')) {
        final data = res['data'];
        if (kDebugMode) {
          debugPrint(
            '[OrderAPI] Found data key, type: ${data.runtimeType}, length: ${data is List ? data.length : 'N/A'}',
          );
        }
        return data is List ? data : [];
      }

      // Handle direct list format
      if (res is List) {
        if (kDebugMode) {
          debugPrint('[OrderAPI] Direct list response, length: ${res.length}');
        }
        return res;
      }

      if (kDebugMode) {
        debugPrint(
          '[OrderAPI] Unexpected response format, returning empty list',
        );
      }
      return [];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[OrderAPI] fetchOrders failed: $e');
        debugPrint('[OrderAPI] Stack trace: $stackTrace');
      }
      return [];
    }
  }

  /// Fetch single order details.
  Future<Map<String, dynamic>?> fetchOrder(String id) async {
    try {
      final res = await _api.getJson('/orders/$id');
      return res is Map && res.containsKey('data') ? res['data'] : res;
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderAPI] fetchOrder failed: $e');
      return null;
    }
  }

  /// Create a new order.
  ///
  /// [customerName] - Guest name or User name
  /// [customerEmail] - Guest/User email
  /// [customerPhone] - Guest/User phone
  /// [deliveryLocation] - Combined address string
  /// [paymentMethod] - 'credit_card', 'cash_on_delivery', etc.
  /// [items] - List of items with {product_id/package_id, qty}
  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryLocation,
    String? feeLocation,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    Map<String, String>? cardDetails,
  }) async {
    try {
      final body = {
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'delivery_location': deliveryLocation,
        if (feeLocation != null) 'fee_location': feeLocation,
        'payment_method': paymentMethod,
        'items': items,
        if (cardDetails != null) 'card_details': cardDetails,
      };

      if (kDebugMode) {
        debugPrint('[OrderAPI] ========== CREATING ORDER ==========');
        debugPrint('[OrderAPI] Customer: $customerName');
        debugPrint('[OrderAPI] Email: $customerEmail');
        debugPrint('[OrderAPI] Phone: $customerPhone');
        debugPrint('[OrderAPI] Delivery: $deliveryLocation');
        debugPrint('[OrderAPI] Fee Location: $feeLocation');
        debugPrint('[OrderAPI] Payment: $paymentMethod');
        debugPrint('[OrderAPI] Items count: ${items.length}');
        debugPrint('[OrderAPI] Full request body: $body');
      }

      final res = await _api.postJson('/orders', body: body);

      if (kDebugMode) {
        debugPrint(
          '[OrderAPI] Order creation response type: ${res.runtimeType}',
        );
        debugPrint('[OrderAPI] Order creation response: $res');
      }

      final orderData = res is Map && res.containsKey('data')
          ? res['data']
          : res;

      if (kDebugMode) {
        debugPrint('[OrderAPI] Created order ID: ${orderData['id']}');
        debugPrint(
          '[OrderAPI] ========== ORDER CREATED SUCCESSFULLY ==========',
        );
      }

      return orderData;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[OrderAPI] ========== ORDER CREATION FAILED ==========');
        debugPrint('[OrderAPI] Error: $e');
        debugPrint('[OrderAPI] Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Delete an order.
  Future<void> deleteOrder(String id) async {
    try {
      if (kDebugMode) {
        debugPrint('[OrderAPI] Deleting order ID: $id');
      }
      await _api.deleteJson('/orders/$id');
    } catch (e) {
      if (kDebugMode) debugPrint('[OrderAPI] deleteOrder failed: $e');
      rethrow;
    }
  }
}
