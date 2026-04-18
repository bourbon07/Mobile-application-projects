import '../api_client.dart';

/// LaravelProfileApiService
///
/// Connects Flutter profile/settings updates to the Laravel backend so profile
/// changes persist and sync with the Vue app.
class LaravelProfileApiService {
  LaravelProfileApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<Map<String, dynamic>> fetchProfile() async {
    final res = await _api.getJson('/profile');
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return const <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? bio,
    String? phone,
    String? location,
    bool? isPrivate,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
      if (isPrivate != null) 'is_private': isPrivate,
    };

    final res = await _api.putJson('/profile', body: body);
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);
    return const <String, dynamic>{};
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    await _api.postJson('/profile/avatar', body: {'avatar_url': avatarUrl});
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _api.postJson(
      '/profile/change-password',
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      },
    );
  }
}
