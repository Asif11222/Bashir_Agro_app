import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/local_storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException(this.statusCode, this.message, [this.errors]);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'ইন্টারনেট সংযোগ পাওয়া যায়নি।']);

  @override
  String toString() => message;
}

class ApiClient {
  static void Function()? onUnauthorized;

  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client() {
    _authToken = LocalStorageService.instance.getString(ApiConstants.tokenKey);
  }

  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null && token.isNotEmpty) {
      LocalStorageService.instance.setString(ApiConstants.tokenKey, token);
    }
  }

  String? get authToken =>
      _authToken ?? LocalStorageService.instance.getString(ApiConstants.tokenKey);

  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final effectiveToken = authToken;
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams, String? overrideBase]) {
    final base = (overrideBase ?? ApiConstants.baseUrl).replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      );
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  String? _getAlternateBaseUrl(String currentBase) {
    if (currentBase.contains('10.0.2.2')) {
      return currentBase.replaceAll('10.0.2.2', '192.168.0.112');
    } else if (currentBase.contains('192.168.0.112')) {
      return currentBase.replaceAll('192.168.0.112', '127.0.0.1');
    } else if (currentBase.contains('127.0.0.1')) {
      return currentBase.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return null;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final uri = _buildUri(path, queryParams);
      var response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));

      if ((response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) &&
          response.headers.containsKey('location')) {
        final redirectLocation = response.headers['location']!;
        final redirectUri = Uri.parse(redirectLocation);
        response = await _client
            .get(redirectUri, headers: _buildHeaders())
            .timeout(const Duration(seconds: 15));
      }

      return _processResponse(response);
    } on SocketException catch (_) {
      final altBase = _getAlternateBaseUrl(ApiConstants.baseUrl);
      if (altBase != null) {
        try {
          final altUri = _buildUri(path, queryParams, altBase);
          final response = await _client
              .get(altUri, headers: _buildHeaders())
              .timeout(const Duration(seconds: 15));
          ApiConstants.baseUrl = altBase;
          return _processResponse(response);
        } catch (_) {}
      }
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('অনুরোধটির সময় শেষ হয়ে গেছে। সার্ভারে সাড়া নেই।');
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic body}) async {
    try {
      final uri = _buildUri(path);
      var response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));

      if ((response.statusCode == 301 || response.statusCode == 302 || response.statusCode == 307 || response.statusCode == 308) &&
          response.headers.containsKey('location')) {
        final redirectLocation = response.headers['location']!;
        final redirectUri = Uri.parse(redirectLocation);
        response = await _client
            .post(
              redirectUri,
              headers: _buildHeaders(),
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 20));
      }

      return _processResponse(response);
    } on SocketException catch (_) {
      final altBase = _getAlternateBaseUrl(ApiConstants.baseUrl);
      if (altBase != null) {
        try {
          final altUri = _buildUri(path, null, altBase);
          final response = await _client
              .post(
                altUri,
                headers: _buildHeaders(),
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(const Duration(seconds: 20));
          ApiConstants.baseUrl = altBase;
          return _processResponse(response);
        } catch (_) {}
      }
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('অনুরোধটির সময় শেষ হয়ে গেছে।');
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      final headers = _buildHeaders();
      headers.remove('Content-Type'); // Let MultipartRequest set boundary
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } on SocketException catch (_) {
      final altBase = _getAlternateBaseUrl(ApiConstants.baseUrl);
      if (altBase != null) {
        try {
          final altUri = _buildUri(path, null, altBase);
          final request = http.MultipartRequest('POST', altUri);
          final headers = _buildHeaders();
          headers.remove('Content-Type');
          request.headers.addAll(headers);
          request.fields.addAll(fields);
          if (files != null) request.files.addAll(files);

          final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 40));
          final response = await http.Response.fromStream(streamedResponse);
          ApiConstants.baseUrl = altBase;
          return _processResponse(response);
        } catch (_) {}
      }
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('ফাইল আপলোড সময় শেষ হয়ে গেছে।');
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded, 'success': true};
    }

    String message;
    if (decoded is Map && decoded['message'] != null) {
      final rawMsg = decoded['message'].toString();
      if (rawMsg.trim().startsWith('<') || rawMsg.contains('<html') || rawMsg.contains('<body')) {
        message = 'সার্ভার সংযোগে সমস্যা হয়েছে (কোড: ${response.statusCode})';
      } else {
        message = rawMsg;
      }
    } else {
      message = 'সার্ভার ত্রুটি: ${response.statusCode}';
    }
    final errors = (decoded is Map && decoded['errors'] != null) ? decoded['errors'] : null;

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }

    throw ApiException(response.statusCode, message, errors);
  }
}
