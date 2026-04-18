import 'package:flutter/foundation.dart';
import '../api_client.dart';

class DeliveryFeeApiService {
  DeliveryFeeApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<dynamic>> fetchDeliveryFees() async {
    try {
      final res = await _api.getJson('/delivery-fees');
      if (res is List) return res;
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch delivery fees failed: $e');
      return [];
    }
  }
}


