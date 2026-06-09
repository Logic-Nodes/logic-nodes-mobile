import 'dart:convert';

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

  factory AuthUserModel.fromBackend({
    required Map<String, dynamic> verifiedUser,
    Map<String, dynamic>? profile,
    String? companyName,
  }) {
    return AuthUserModel(
      id: '${verifiedUser['id']}',
      name: _resolveName(
        profile: profile,
        email: verifiedUser['email'] as String? ?? '',
      ),
      email: verifiedUser['email'] as String? ?? '',
      role: roleFromBackendRoles(verifiedUser['roles']),
      companyName: companyName,
    );
  }

  AuthUser toDomain() {
    return AuthUser(
      id: id,
      name: name,
      email: email,
      role: role,
      companyName: companyName,
    );
  }

  static UserRole roleFromBackendRoles(Object? rawRoles) {
    if (rawRoles is Iterable) {
      final roles = rawRoles
          .map((role) => '$role'.trim().toUpperCase())
          .where((role) => role.isNotEmpty);

      if (roles.any((role) => role.contains('CUSTOMER'))) {
        return UserRole.customer;
      }
    }

    return UserRole.fleetManager;
  }

  static String _resolveName({
    required Map<String, dynamic>? profile,
    required String email,
  }) {
    final firstName = profile?['firstName'] as String?;
    final lastName = profile?['lastName'] as String?;
    final fullName = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) {
      return 'OmniTrack User';
    }

    return prefix
        .split(RegExp(r'[._-]+'))
        .where((chunk) => chunk.isNotEmpty)
        .map((chunk) => '${chunk[0].toUpperCase()}${chunk.substring(1)}')
        .join(' ');
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

  factory AuthSessionModel.fromBackend({
    required Map<String, dynamic> tokenPair,
    required Map<String, dynamic> verifiedUser,
    Map<String, dynamic>? profile,
    String? companyName,
  }) {
    final accessToken = tokenPair['accessToken'] as String? ?? '';
    final refreshToken = tokenPair['refreshToken'] as String? ?? '';

    return AuthSessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUserModel.fromBackend(
        verifiedUser: verifiedUser,
        profile: profile,
        companyName: companyName,
      ),
      expiresAt: _extractExpiryFromJwt(accessToken),
    );
  }

  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toDomain(),
      expiresAt: expiresAt,
    );
  }

  static DateTime _extractExpiryFromJwt(String token) {
    try {
      final segments = token.split('.');
      if (segments.length < 2) {
        throw const FormatException('Invalid JWT structure');
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      ) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      }
    } on Exception {
      // Fallback keeps the UI responsive if the token payload is not decodable.
    }

    return DateTime.now().add(const Duration(hours: 1));
  }
}
