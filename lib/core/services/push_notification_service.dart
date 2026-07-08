import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class PushNotificationService {
  PushNotificationService({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission();
      }

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint(
          '[fcm] foreground: ${message.notification?.title} — ${message.notification?.body}',
        );
      });
    } on Exception catch (error) {
      debugPrint('[fcm] initialize skipped: $error');
    }
  }

  Future<void> syncTokenForUser(String userId) async {
    if (!_initialized) {
      return;
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'unknown';

      await _apiClient.post(
        '/api/v1/device-tokens',
        body: {
          'userId': userId,
          'token': token,
          'platform': platform,
        },
        expectedStatusCodes: const {201},
      );

      debugPrint('[fcm] token registered for user $userId ($platform)');
    } on Exception catch (error) {
      debugPrint('[fcm] token sync failed: $error');
    }
  }
}
