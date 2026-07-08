import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/auth_session_codec.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import 'session_store.dart';

class PersistentSessionStore implements SessionStore {
  PersistentSessionStore({
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  static const _storageKey = 'omnitrack.auth_session';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AuthSession?> read() async {
    final raw = (await _prefs).getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AuthSessionCodec.fromJson(decoded);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final encoded = jsonEncode(AuthSessionCodec.toJson(session));
    await (await _prefs).setString(_storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    await (await _prefs).remove(_storageKey);
  }
}
