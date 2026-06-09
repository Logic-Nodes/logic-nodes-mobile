import 'package:flutter_test/flutter_test.dart';
import 'package:logic_nodes_mobile/core/errors/app_exception.dart';
import 'package:logic_nodes_mobile/features/auth/application/use_cases/sign_in_use_case.dart';
import 'package:logic_nodes_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:logic_nodes_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:logic_nodes_mobile/features/auth/domain/repositories/auth_repository.dart';

void main() {
  group('SignInUseCase', () {
    test('rejects malformed emails before repository access', () async {
      final useCase = SignInUseCase(_FakeAuthRepository());

      expect(
        () => useCase(
          email: 'wrong-email',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('delegates valid credentials to repository', () async {
      final repository = _FakeAuthRepository();
      final useCase = SignInUseCase(repository);

      await useCase(
        email: 'fleet@omnitrack.io',
        password: 'password123',
      );

      expect(repository.receivedEmail, 'fleet@omnitrack.io');
      expect(repository.receivedPassword, 'password123');
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  String? receivedEmail;
  String? receivedPassword;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    receivedEmail = email;
    receivedPassword = password;
    return Future.value(
      AuthSession(
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2030),
        user: const AuthUser(
          id: '1',
          name: 'Tester',
          email: 'fleet@omnitrack.io',
          role: UserRole.fleetManager,
        ),
      ),
    );
  }

  @override
  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registerCompany({
    required String companyContactEmail,
    required String legalName,
    required String taxId,
    required String fiscalAddress,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required String password,
  }) async {}

  @override
  Future<void> requestPasswordReset({
    required String email,
  }) async {}

  @override
  Future<void> resetPassword({
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}
