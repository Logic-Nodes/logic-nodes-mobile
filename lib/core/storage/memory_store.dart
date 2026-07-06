import '../../features/auth/domain/entities/auth_session.dart';
import 'session_store.dart';

class MemoryStore<T> {
  T? _value;

  T? read() => _value;

  Future<void> write(T value) async {
    _value = value;
  }

  Future<void> clear() async {
    _value = null;
  }
}

class MemorySessionStore implements SessionStore {
  final MemoryStore<AuthSession> _store = MemoryStore<AuthSession>();

  @override
  Future<AuthSession?> read() async => _store.read();

  @override
  Future<void> write(AuthSession session) => _store.write(session);

  @override
  Future<void> clear() => _store.clear();
}
