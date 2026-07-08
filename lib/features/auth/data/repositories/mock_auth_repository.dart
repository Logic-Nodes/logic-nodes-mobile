import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/mock_auth_datasource.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    required this.datasource,
  });

  final MockAuthDatasource datasource;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final session = await datasource.signIn(
      email: email,
      password: password,
    );

    return session.toDomain();
  }

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
  }) {
    return datasource.registerCompany(
      companyContactEmail: companyContactEmail,
      legalName: legalName,
      taxId: taxId,
      fiscalAddress: fiscalAddress,
      adminFirstName: adminFirstName,
      adminLastName: adminLastName,
      adminEmail: adminEmail,
      password: password,
    );
  }

  @override
  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    return datasource.registerClient(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
  }) {
    return datasource.requestPasswordReset(email: email);
  }

  @override
  Future<void> resetPassword({
    required String password,
  }) {
    return datasource.resetPassword(password: password);
  }

  @override
  Future<AuthSession> refreshSession({
    required AuthSession currentSession,
  }) async {
    return AuthSession(
      accessToken: currentSession.accessToken,
      refreshToken: currentSession.refreshToken,
      user: currentSession.user,
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }

  @override
  Future<void> signOut({
    String? refreshToken,
  }) {
    return datasource.signOut();
  }

  @override
  Future<void> signOutAll({
    required String accessToken,
    required String userId,
  }) async {}
}
