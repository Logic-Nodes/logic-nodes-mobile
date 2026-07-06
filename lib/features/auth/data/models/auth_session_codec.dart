import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

abstract final class AuthSessionCodec {
  static Map<String, dynamic> toJson(AuthSession session) {
    return {
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'expiresAt': session.expiresAt.toUtc().toIso8601String(),
      'user': {
        'id': session.user.id,
        'name': session.user.name,
        'email': session.user.email,
        'role': session.user.role.name,
        if (session.user.companyName != null)
          'companyName': session.user.companyName,
      },
    };
  }

  static AuthSession fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];
    if (userMap is! Map<String, dynamic>) {
      throw const FormatException('Missing user payload in stored session.');
    }

    return AuthSession(
      accessToken: _requireString(json['accessToken']),
      refreshToken: _requireString(json['refreshToken']),
      expiresAt: DateTime.parse(_requireString(json['expiresAt'])).toLocal(),
      user: AuthUser(
        id: _requireString(userMap['id']),
        name: _requireString(userMap['name']),
        email: _requireString(userMap['email']),
        role: _roleFromStored(userMap['role']),
        companyName: _nullableString(userMap['companyName']),
      ),
    );
  }

  static String _requireString(Object? value) {
    final normalized = '$value'.trim();
    if (normalized.isEmpty || normalized == 'null') {
      throw const FormatException('Invalid stored session field.');
    }

    return normalized;
  }

  static String? _nullableString(Object? value) {
    final normalized = '$value'.trim();
    if (normalized.isEmpty || normalized == 'null') {
      return null;
    }

    return normalized;
  }

  static UserRole _roleFromStored(Object? value) {
    final normalized = '$value'.trim();
    if (normalized == UserRole.customer.name) {
      return UserRole.customer;
    }

    return UserRole.fleetManager;
  }
}
