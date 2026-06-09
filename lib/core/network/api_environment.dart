import 'package:flutter/foundation.dart';

abstract final class ApiEnvironment {
  static const _overrideBaseUrl = String.fromEnvironment(
    'OMNITRACK_API_BASE_URL',
  );

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:3000',
      TargetPlatform.iOS => 'http://localhost:3000',
      TargetPlatform.macOS => 'http://localhost:3000',
      TargetPlatform.windows => 'http://localhost:3000',
      TargetPlatform.linux => 'http://localhost:3000',
      TargetPlatform.fuchsia => 'http://localhost:3000',
    };
  }

  static String get docsUrl => '$baseUrl/docs';
}
