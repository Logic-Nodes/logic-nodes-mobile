import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (!_looksLikeEmail(normalizedEmail)) {
      throw const AuthException('Ingresa una dirección de correo válida.');
    }

    if (normalizedPassword.length < 8) {
      throw const AuthException(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }

    return _authRepository.signIn(
      email: normalizedEmail,
      password: normalizedPassword,
    );
  }

  bool _looksLikeEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}
