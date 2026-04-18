library;

import 'package:flutter/foundation.dart';

import '../api_client.dart';

/// LaravelCloudinaryApiService
///
/// Bridges Flutter UI to your Laravel Cloudinary controller.
///
/// Supports:
/// - Fetching Cloudinary images (GET)
/// - Uploading via remote URL (POST JSON)
/// - Uploading via file (POST multipart/form-data)
class LaravelCloudinaryApiService {
  LaravelCloudinaryApiService({ApiClient? api})
    : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetch existing Cloudinary images (list of URLs).
  Future<List<String>> fetchImages() async {
    const path = '/list-images';
    try {
      final res = await _api.getJson(path);
      return _extractUrls(res);
    } catch (e) {
      if (kDebugMode) debugPrint('Cloudinary fetchImages failed ($path): $e');
      return const [];
    }
  }

  /// Upload to Cloudinary using a **remote URL**.
  Future<String> uploadFromUrl(String sourceUrl) async {
    final url = sourceUrl.trim();
    if (url.isEmpty) throw Exception('Image URL is empty');

    const path = '/upload-image';
    try {
      final res = await _api.postJson(
        path,
        body: {'url': url, 'image_url': url, 'upload_to_cloudinary': true},
      );
      final uploaded = _extractSingleUrl(res);
      if (uploaded != null && uploaded.isNotEmpty) return uploaded;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cloudinary uploadFromUrl failed ($path): $e');
      }
    }

    throw Exception('Failed to upload image to Cloudinary');
  }

  /// Upload a file to Cloudinary via multipart/form-data.
  Future<String> uploadFile({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    const path = '/upload-image';

    try {
      final res = await _api.postMultipart(
        path,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        fieldName: 'image',
        additionalFields: {'upload_to_cloudinary': 'true'},
      );
      final uploaded = _extractSingleUrl(res);
      if (uploaded != null && uploaded.isNotEmpty) return uploaded;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cloudinary uploadFile failed ($path): $e');
      }
    }

    throw Exception('Failed to upload file to Cloudinary');
  }

  List<String> _extractUrls(dynamic res) {
    if (res is List) {
      return _parseUrlList(res);
    }
    if (res is Map) {
      final candidates = [
        res['images'],
        res['data'],
        res['urls'],
        res['resources'],
      ];
      for (final c in candidates) {
        if (c is List) {
          return _parseUrlList(c);
        }
      }
    }
    return const [];
  }

  List<String> _parseUrlList(List list) {
    final urls = <String>[];
    for (final item in list) {
      if (item is String && item.isNotEmpty) {
        urls.add(item);
      } else if (item is Map) {
        // Handlers for common Cloudinary/Laravel response structures
        final url = item['url'] ?? item['secure_url'] ?? item['image_url'];
        if (url is String && url.isNotEmpty) {
          urls.add(url);
        }
      }
    }
    return urls;
  }

  String? _extractSingleUrl(dynamic res) {
    if (res is Map) {
      for (final key in const ['url', 'secure_url']) {
        final v = res[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      // Common Laravel wrappers: { data: { url: "..." } }
      final data = res['data'];
      if (data is Map) {
        for (final key in const ['url', 'secure_url']) {
          final v = data[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
    }
    return null;
  }
}
