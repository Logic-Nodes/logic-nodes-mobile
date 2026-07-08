import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<void> registerCompany({
    required String companyContactEmail,
    required String legalName,
    required String taxId,
    required String fiscalAddress,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required String password,
  });

  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset({
    required String email,
  });

  Future<void> resetPassword({
    required String password,
  });

  Future<AuthSession> refreshSession({
    required AuthSession currentSession,
  });

  Future<void> signOut({
    String? refreshToken,
  });

  Future<void> signOutAll({
    required String accessToken,
    required String userId,
  });
}
