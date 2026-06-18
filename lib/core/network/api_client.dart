import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 12),
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

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
    Set<int> expectedStatusCodes = const {200},
  }) {
    return _request(
      'GET',
      path,
      headers: headers,
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
    required Set<int> expectedStatusCodes,
  }) async {
    final uri = endpoint(path);
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      ...?headers,
    };

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
      throw AppException('The request to $uri timed out.');
    } on Exception catch (exception) {
      throw AppException('Unable to reach $uri. $exception');
    }

    final responseBody = _decodeBody(response.body);

    if (!expectedStatusCodes.contains(response.statusCode)) {
      final message = _extractErrorMessage(responseBody) ??
          'Request failed with status ${response.statusCode}.';
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    return responseBody;
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
