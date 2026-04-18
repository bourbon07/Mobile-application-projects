import '../api_client.dart';

/// CatalogApiService - Fetch public catalog data from Laravel.
class CatalogApiService {
  CatalogApiService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<dynamic>> fetchProducts() async {
    final res = await _api.getJson('/products');
    // Laravel returns either a list, OR { products: [...], ... } when searching.
    if (res is List) return res;
    if (res is Map<String, dynamic> && res['products'] is List) {
      return res['products'] as List;
    }
    throw Exception('Invalid products response');
  }

  Future<List<dynamic>> fetchCategories() async {
    final res = await _api.getJson('/categories');
    if (res is List) return res;
    throw Exception('Invalid categories response');
  }

  Future<List<dynamic>> fetchPackages() async {
    final res = await _api.getJson('/packages');
    if (res is List) return res;
    throw Exception('Invalid packages response');
  }

  Future<Map<String, dynamic>> fetchProductById(String id) async {
    final res = await _api.getJson('/products/$id');
    if (res is Map<String, dynamic>) {
      // Support wrapped response { data: {...} } or direct {...}
      if (res.containsKey('data') && res['data'] is Map<String, dynamic>) {
        return res['data'];
      }
      return res;
    }
    throw Exception('Invalid product response');
  }

  Future<List<dynamic>> fetchProductComments(String productId) async {
    final res = await _api.getJson('/products/$productId/comments');
    if (res is List) return res;
    throw Exception('Invalid comments response');
  }

  Future<Map<String, dynamic>> postProductComment(
    String productId,
    String comment,
    int rating,
  ) async {
    final res = await _api.postJson(
      '/products/$productId/comments',
      body: {'comment': comment, 'rating': rating},
    );
    return res as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchPackageComments(String packageId) async {
    final res = await _api.getJson('/packages/$packageId/comments');
    if (res is List) return res;
    throw Exception('Invalid comments response');
  }

  Future<Map<String, dynamic>> postPackageComment(
    String packageId,
    String comment,
    int rating,
  ) async {
    final res = await _api.postJson(
      '/packages/$packageId/comments',
      body: {'comment': comment, 'rating': rating},
    );
    return res as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchProductRating(String productId) async {
    final res = await _api.getJson('/products/$productId/rating');
    if (res is Map<String, dynamic>) {
      if (res.containsKey('data') && res['data'] is Map<String, dynamic>) {
        return res['data'];
      }
      return res;
    }
    return {'average_rating': 0, 'total_ratings': 0, 'user_rating': null};
  }

  Future<Map<String, dynamic>> fetchPackageRating(String packageId) async {
    final res = await _api.getJson('/packages/$packageId/rating');
    if (res is Map<String, dynamic>) {
      if (res.containsKey('data') && res['data'] is Map<String, dynamic>) {
        return res['data'];
      }
      return res;
    }
    return {'average_rating': 0, 'total_ratings': 0, 'user_rating': null};
  }
}
