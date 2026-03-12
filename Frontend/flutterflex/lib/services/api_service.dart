import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client, FlutterSecureStorage? secureStorage})
    : _client = client ?? http.Client(),
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:5000/api';
  static const String _localDesktopBaseUrl = 'http://localhost:5000/api';
  static const String _tokenKey = 'jwt_token';

  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  String? _token;

  String get baseUrl {
    if (kIsWeb) {
      return _localDesktopBaseUrl;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidEmulatorBaseUrl,
      _ => _localDesktopBaseUrl,
    };
  }

  Future<void> loadToken() async {
    _token = await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<Map<String, String>> _buildHeaders({
    bool authenticated = false,
  }) async {
    if (authenticated && _token == null) {
      await loadToken();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Uri _buildUri(String endpoint) {
    return Uri.parse('$baseUrl$endpoint');
  }

  Future<dynamic> get(String endpoint, {bool authenticated = false}) async {
    final response = await _client.get(
      _buildUri(endpoint),
      headers: await _buildHeaders(authenticated: authenticated),
    );

    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final response = await _client.post(
      _buildUri(endpoint),
      headers: await _buildHeaders(authenticated: authenticated),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final response = await _client.put(
      _buildUri(endpoint),
      headers: await _buildHeaders(authenticated: authenticated),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {bool authenticated = false}) async {
    final response = await _client.delete(
      _buildUri(endpoint),
      headers: await _buildHeaders(authenticated: authenticated),
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final hasBody = response.body.isNotEmpty;
    final decodedBody = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final message = decodedBody is Map<String, dynamic>
        ? decodedBody['message']?.toString() ??
              decodedBody['error']?.toString() ??
              'Unbekannter Serverfehler'
        : 'Unbekannter Serverfehler';

    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
