import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.companyName,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? companyName;

  AuthUser toDomain() {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      role: role,
      companyName: companyName,
    );
  }
}

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserModel user;
  final DateTime expiresAt;

  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toDomain(),
      expiresAt: expiresAt,
    );
  }
}
