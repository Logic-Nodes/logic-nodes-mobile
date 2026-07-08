import '../../features/auth/domain/entities/auth_session.dart';

abstract class SessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}
