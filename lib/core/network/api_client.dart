import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 12),
    this.getAccessToken,
    this.onUnauthorized,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  final Duration timeout;
  final String? Function()? getAccessToken;
  final Future<bool> Function()? onUnauthorized;

  Uri endpoint(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
  }

  Future<Object?> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
      expectedStatusCodes: expectedStatusCodes,
    );
  }

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'POST',
      path,
      body: body,
      headers: headers,
      expectedStatusCodes: expectedStatusCodes,
    );
  }

  Future<Object?> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      headers: headers,
      expectedStatusCodes: expectedStatusCodes,
    );
  }

  Future<Object?> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      headers: headers,
      expectedStatusCodes: expectedStatusCodes,
    );
  }

  Future<Object?> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'DELETE',
      path,
      body: body,
      headers: headers,
      expectedStatusCodes: expectedStatusCodes,
    );
  }

  Future<Object?> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    required Set<int> expectedStatusCodes,
    bool hasRetriedAuth = false,
  }) async {
    final uri = endpoint(path, queryParameters: queryParameters);
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...?headers,
    };

    if (hasRetriedAuth) {
      final accessToken = getAccessToken?.call();
      if (accessToken != null && accessToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $accessToken';
      }
    }

    late http.Response response;

    try {
      response = switch (method) {
        'GET' => await _httpClient
            .get(uri, headers: requestHeaders)
            .timeout(timeout),
        'POST' => await _httpClient
            .post(
              uri,
              headers: requestHeaders,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout),
        'PUT' => await _httpClient
            .put(
              uri,
              headers: requestHeaders,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout),
        'PATCH' => await _httpClient
            .patch(
              uri,
              headers: requestHeaders,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout),
        'DELETE' => await _httpClient
            .delete(
              uri,
              headers: requestHeaders,
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(timeout),
        _ => throw UnsupportedError('HTTP method $method is not supported.'),
      };
    } on TimeoutException {
      throw AppException('La solicitud excedió el tiempo de espera.');
    } on Exception catch (exception) {
      throw AppException('No se pudo conectar con el servidor. $exception');
    }

    if (response.statusCode == 401 &&
        !hasRetriedAuth &&
        onUnauthorized != null &&
        _shouldRetryAuth(path)) {
      final refreshed = await onUnauthorized!();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          headers: headers,
          queryParameters: queryParameters,
          expectedStatusCodes: expectedStatusCodes,
          hasRetriedAuth: true,
        );
      }
    }

    final responseBody = _decodeBody(response.body);

    if (!expectedStatusCodes.contains(response.statusCode)) {
      final message = _extractErrorMessage(responseBody) ??
          'La solicitud falló con el código ${response.statusCode}.';
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    return responseBody;
  }

  bool _shouldRetryAuth(String path) {
    return !path.startsWith('/api/v1/authentication/');
  }

  Object? _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } on FormatException {
      return rawBody;
    }
  }

  String? _extractErrorMessage(Object? responseBody) {
    if (responseBody is Map<String, dynamic>) {
      final message = responseBody['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (responseBody is String && responseBody.trim().isNotEmpty) {
      return responseBody;
    }

    return null;
  }
}
