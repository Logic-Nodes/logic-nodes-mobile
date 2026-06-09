class ApiClient {
  const ApiClient({
    required this.baseUrl,
  });

  final String baseUrl;

  Uri endpoint(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
  }
}
