import 'package:flutter/foundation.dart';

import '../api_client.dart';

/// LaravelChatApiService
///
/// Uses the same REST endpoints the Vue app uses (Laravel backend).
/// This enables cross-platform chat (Vue <-> Flutter) without requiring
/// WebSocket dependencies. "Real-time" is achieved via polling in the UI.
class LaravelChatApiService {
  LaravelChatApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final res = await _api.getJson('/conversations');
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String otherUserId) async {
    final res = await _api.getJson('/messages/$otherUserId');
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final res = await _api.getJson('/users/$userId/profile');
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchUserProfile primary failed: $e');
    }
    try {
      final res = await _api.getJson('/admin/users/$userId');
      if (res is Map) return Map<String, dynamic>.from(res);
    } catch (e) {
      if (kDebugMode) debugPrint('fetchUserProfile admin fallback failed: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchAdmins() async {
    final res = await _api.getJson('/admins');
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> sendMessage({
    required String toUserId,
    required String message,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'to_user_id': toUserId,
      'message': message,
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'image_url': imageUrl,
    };
    final res = await _api.postJson('/messages', body: body);
    if (res is Map) return Map<String, dynamic>.from(res);
    return const <String, dynamic>{};
  }

  Future<void> markRead(String otherUserId) async {
    await _api.postJson('/chat/$otherUserId/read');
  }

  Future<void> deleteMessage(String messageId) async {
    await _api.deleteJson('/messages/$messageId');
  }
}




