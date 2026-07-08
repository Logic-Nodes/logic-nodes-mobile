abstract final class ApiEnvironment {
  static const productionBaseUrl =
      'https://logic-nodes-server.onrender.com';

  /// Backend local en el Mac. En simulador iOS usa 127.0.0.1 (no localhost).
  static const localIosBaseUrl = 'http://127.0.0.1:3001';

  static const localAndroidEmulatorBaseUrl = 'http://10.0.2.2:3001';

  static const _overrideBaseUrl = String.fromEnvironment(
    'OMNITRACK_API_BASE_URL',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    return productionBaseUrl;
  }

  static String get docsUrl => '$baseUrl/docs';

  static const localDevDartDefineHint =
      'Para backend local en iOS/macOS: '
      '--dart-define=OMNITRACK_API_BASE_URL=$localIosBaseUrl. '
      'En Android emulator: $localAndroidEmulatorBaseUrl. '
      'Render puede tardar ~30s en despertar; la app espera hasta 45s.';
}
