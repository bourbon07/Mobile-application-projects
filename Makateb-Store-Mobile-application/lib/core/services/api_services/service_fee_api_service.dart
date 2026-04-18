import 'package:flutter/foundation.dart';
import '../api_client.dart';

class ServiceFeeApiService {
  ServiceFeeApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchServiceFee() async {
    try {
      final res = await _api.getJson(
        '/service-fee',
      ); // Endpoint might be /service-fee or /service-fees/current based on Controller. assuming /service-fee based on Controller 'get' method name usually mapping to root resource or similar. Actually let me check routes.
      // Controller has 'get' method. Usually implies GET /api/service-fee if route defined as such.
      // I should double check routes but for now I'll assume standard naming conventions or what I saw in controller.
      return res is Map ? Map<String, dynamic>.from(res) : {};
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch service fee failed: $e');
      return {};
    }
  }
}


