import 'package:flutter/foundation.dart';

import '../../../../core/storage/offline_cache_store.dart';
import '../../../../core/storage/session_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.sessionStore,
    required this.authRepository,
    this.offlineCacheStore,
  });

  final SessionStore sessionStore;
  final AuthRepository authRepository;
  final OfflineCacheStore? offlineCacheStore;

  AuthSession? _session;
  bool _isSigningOut = false;
  bool _isRestoring = false;
  bool _isRefreshing = false;

  AuthSession? get session => _session;
  bool get isAuthenticated => session != null;
  bool get isSigningOut => _isSigningOut;
  bool get isRestoring => _isRestoring;

  String? get accessToken => session?.accessToken;

  Future<void> restore() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final stored = await sessionStore.read();
      if (stored == null) {
        return;
      }

      _session = stored;

      final shouldRefresh = stored.expiresAt.isBefore(
        DateTime.now().add(const Duration(minutes: 2)),
      );
      if (shouldRefresh) {
        await tryRefreshSession();
      }
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> tryRefreshSession() async {
    final current = session;
    if (current == null || _isRefreshing) {
      return current != null;
    }

    _isRefreshing = true;

    try {
      final refreshed = await authRepository.refreshSession(
        currentSession: current,
      );
      await open(refreshed);
      return true;
    } on Exception {
      await _clearLocalSession();
      return false;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> open(AuthSession nextSession) async {
    await sessionStore.write(nextSession);
    _session = nextSession;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    notifyListeners();

    final refreshToken = session?.refreshToken;
    await authRepository.signOut(refreshToken: refreshToken);
    await _clearLocalSession();
    _isSigningOut = false;
    notifyListeners();
  }

  Future<void> signOutAll() async {
    _isSigningOut = true;
    notifyListeners();

    final current = session;
    if (current != null) {
      await authRepository.signOutAll(
        accessToken: current.accessToken,
        userId: current.user.id,
      );
    }

    await authRepository.signOut(refreshToken: current?.refreshToken);
    await _clearLocalSession();
    _isSigningOut = false;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    final userId = _session?.user.id;
    await sessionStore.clear();
    if (userId != null) {
      await offlineCacheStore?.clearUser(userId);
    }
    _session = null;
  }
}
