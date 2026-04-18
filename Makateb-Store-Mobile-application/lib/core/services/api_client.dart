import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'http_config_service.dart';

/// ApiClient - Minimal HTTP client for the Laravel backend.
///
/// - Uses `HttpConfigService` for default headers (Accept-Language, Authorization).
/// - Parses JSON responses and throws readable exceptions on non-2xx.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = HttpConfigService.instance.baseUrl ?? ApiConfig.baseUrl;
    final cleanedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanedPath = path.startsWith('/') ? path : '/$path';

    final uri = Uri.parse('$cleanedBase$cleanedPath');
    if (query == null || query.isEmpty) return uri;

    return uri.replace(
      queryParameters: query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    final base = HttpConfigService.instance.defaultHeaders;
    if (kDebugMode && base.containsKey('X-Guest-Id')) {
      debugPrint('[ApiClient] X-Guest-Id: ${base['X-Guest-Id']}');
    }
    if (extra == null || extra.isEmpty) return base;
    return {...base, ...extra};
  }

  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    final uri = _uri(path, query);
    if (kDebugMode) debugPrint('GET $uri');
    final res = await http.get(uri, headers: _headers());
    return _decodeOrThrow(res);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = _uri(path, query);
    if (kDebugMode) debugPrint('POST $uri');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeOrThrow(res);
  }

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final uri = _uri(path, query);
    if (kDebugMode) debugPrint('PUT $uri');
    final res = await http.put(
      uri,
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decodeOrThrow(res);
  }

  Future<dynamic> deleteJson(String path, {Map<String, dynamic>? query}) async {
    final uri = _uri(path, query);
    if (kDebugMode) debugPrint('DELETE $uri');
    final res = await http.delete(uri, headers: _headers());
    return _decodeOrThrow(res);
  }

  /// Upload file via multipart/form-data.
  ///
  /// [filePath] is the local file path (from image_picker or file_picker).
  /// [fileBytes] and [fileName] are used for platforms like Web.
  /// [fieldName] is the form field name (default: 'image' or 'file').
  /// [additionalFields] are extra form fields to include.
  Future<dynamic> postMultipart(
    String path, {
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
    String fieldName = 'image',
    Map<String, String>? additionalFields,
  }) async {
    final uri = _uri(path);
    if (kDebugMode) debugPrint('POST (multipart) $uri');

    final request = http.MultipartRequest('POST', uri);

    // Add headers (excluding Content-Type, which multipart sets automatically)
    final headers = _headers();
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    // Add file
    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );
    } else if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    } else {
      throw Exception('Either filePath or fileBytes must be provided');
    }

    // Add additional fields
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);
    return _decodeOrThrow(res);
  }

  dynamic _decodeOrThrow(http.Response res) {
    final body = res.body.trim();
    final status = res.statusCode;

    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        decoded = body;
      }
    }

    if (status >= 200 && status < 300) return decoded;

    // Laravel common formats:
    // - { message: "...", errors: {...} }
    // - ValidationException => { message: "...", errors: {field: [..]} }
    final message = () {
      if (decoded is Map<String, dynamic>) {
        final m = decoded['message'];
        if (m is String && m.isNotEmpty) return m;
      }
      if (decoded is String && decoded.isNotEmpty) return decoded;
      return 'Request failed ($status)';
    }();

    throw Exception(message);
  }
}
