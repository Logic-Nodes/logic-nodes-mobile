import 'package:flutter/foundation.dart';

import '../../../../core/storage/memory_store.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.sessionStore,
    required this.authRepository,
  });

  final MemoryStore<AuthSession> sessionStore;
  final AuthRepository authRepository;

  AuthSession? _session;
  bool _isSigningOut = false;

  AuthSession? get session => _session ?? sessionStore.read();
  bool get isAuthenticated => session != null;
  bool get isSigningOut => _isSigningOut;

  Future<void> open(AuthSession nextSession) async {
    await sessionStore.write(nextSession);
    _session = nextSession;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isSigningOut = true;
    notifyListeners();

    await authRepository.signOut();
    await sessionStore.clear();
    _session = null;
    _isSigningOut = false;
    notifyListeners();
  }
}
