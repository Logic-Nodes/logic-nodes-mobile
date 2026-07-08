import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_environment.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_session_model.dart';

class RemoteAuthDatasource {
  RemoteAuthDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;
  String? _lastResetToken;

  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final tokenPair = await apiClient.post(
        '/api/v1/authentication/sign-in',
        body: {
          'email': email,
          'password': password,
        },
        expectedStatusCodes: const {200},
      );

      final tokenMap = _expectMap(tokenPair, 'sign-in response');
      final accessToken = _expectString(tokenMap['accessToken'], 'accessToken');
      final refreshToken =
          _expectString(tokenMap['refreshToken'], 'refreshToken');

      final verifiedUser = await apiClient.post(
        '/api/v1/authentication/verify-token',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      final verifiedUserMap = _expectMap(verifiedUser, 'verify-token response');
      final userId = _expectString(verifiedUserMap['id'], 'user id');
      final role = AuthUserModel.roleFromBackendRoles(verifiedUserMap['roles']);
      final profile = await _tryGetMap(
        '/api/v1/profiles/user/$userId',
        headers: _authHeaders(accessToken),
      );
      final companyName = role == UserRole.fleetManager
          ? await _resolveCompanyName(
              accessToken: accessToken,
              userId: userId,
            )
          : null;

      return AuthSessionModel.fromBackend(
        tokenPair: tokenMap,
        verifiedUser: verifiedUserMap,
        profile: profile,
        companyName: companyName,
      );
    } on ApiException catch (exception) {
      if (exception.statusCode == 401) {
        throw const AuthException(
          'No se pudo autenticar. Revisa tus credenciales e inténtalo de nuevo.',
        );
      }

      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(
        '${exception.message} ${ApiEnvironment.localDevDartDefineHint}',
      );
    }
  }

  Future<AuthSessionModel> refreshSession({
    required String refreshToken,
    required AuthUserModel user,
  }) async {
    try {
      final tokenPair = await apiClient.post(
        '/api/v1/authentication/refresh',
        body: {
          'refreshToken': refreshToken,
        },
        expectedStatusCodes: const {200},
      );

      return AuthSessionModel.fromTokenPair(
        tokenPair: _expectMap(tokenPair, 'refresh response'),
        user: user,
      );
    } on ApiException catch (exception) {
      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(exception.message);
    }
  }

  Future<void> registerCompany({
    required String companyContactEmail,
    required String legalName,
    required String taxId,
    required String fiscalAddress,
    required String adminFirstName,
    required String adminLastName,
    required String adminEmail,
    required String password,
  }) async {
    try {
      final createdUser = await apiClient.post(
        '/api/v1/authentication/sign-up',
        body: {
          'email': adminEmail,
          'password': password,
          'roles': ['FLEET_MANAGER'],
        },
        expectedStatusCodes: const {201},
      );
      final userMap = _expectMap(createdUser, 'sign-up response');
      final userId = _expectString(userMap['id'], 'user id');

      await apiClient.post(
        '/api/v1/profiles',
        body: {
          'firstName': adminFirstName,
          'lastName': adminLastName,
          'userId': _toInt(userId),
        },
        expectedStatusCodes: const {201},
      );

      final merchant = await apiClient.post(
        '/api/v1/merchants',
        body: {
          'name': legalName,
          'contactEmail': companyContactEmail,
          'fiscalAddress': fiscalAddress,
          'ruc': taxId,
          'isActive': true,
        },
        expectedStatusCodes: const {201},
      );
      final merchantMap = _expectMap(merchant, 'merchant response');
      final merchantId = _expectString(merchantMap['id'], 'merchant id');

      await apiClient.post(
        '/api/v1/merchants/$merchantId/employee',
        body: {
          'userId': _toInt(userId),
        },
        expectedStatusCodes: const {201},
      );
    } on ApiException catch (exception) {
      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(exception.message);
    }
  }

  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final createdUser = await apiClient.post(
        '/api/v1/authentication/sign-up',
        body: {
          'email': email,
          'password': password,
          'roles': ['CUSTOMER'],
        },
        expectedStatusCodes: const {201},
      );
      final userMap = _expectMap(createdUser, 'sign-up response');
      final userId = _expectString(userMap['id'], 'user id');

      await apiClient.post(
        '/api/v1/profiles',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'userId': _toInt(userId),
        },
        expectedStatusCodes: const {201},
      );
    } on ApiException catch (exception) {
      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(exception.message);
    }
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/authentication/forgot-password',
        body: {
          'email': email,
        },
        expectedStatusCodes: const {200},
      );

      final responseMap = _expectMap(response, 'forgot-password response');
      final resetToken = responseMap['resetToken'];
      _lastResetToken =
          resetToken is String && resetToken.trim().isNotEmpty
              ? resetToken
              : null;
    } on ApiException catch (exception) {
      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(exception.message);
    }
  }

  Future<void> resetPassword({
    required String password,
  }) async {
    final resetToken = _lastResetToken;
    if (resetToken == null) {
      throw const AuthException(
        'No encontramos una cuenta con ese correo. Vuelve a solicitar las '
        'instrucciones de recuperación para continuar.',
      );
    }

    try {
      await apiClient.post(
        '/api/v1/authentication/reset-password',
        body: {
          'resetToken': resetToken,
          'password': password,
        },
        expectedStatusCodes: const {200},
      );
      _lastResetToken = null;
    } on ApiException catch (exception) {
      throw AuthException(exception.message);
    } on AppException catch (exception) {
      throw AuthException(exception.message);
    }
  }

  Future<void> signOutAll({
    required String accessToken,
    required String userId,
  }) async {
    try {
      await apiClient.post(
        '/api/v1/authentication/logout-all',
        headers: _authHeaders(accessToken),
        body: {
          'userId': userId,
        },
        expectedStatusCodes: const {200, 204},
      );
    } on AppException {
      // Local sign-out should continue even when the backend is unavailable.
    }
  }

  Future<void> signOut({
    required String? refreshToken,
  }) async {
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }

    try {
      await apiClient.post(
        '/api/v1/authentication/logout',
        body: {
          'refreshToken': refreshToken,
        },
        expectedStatusCodes: const {204},
      );
    } on AppException {
      // Local sign-out should continue even when the backend is unavailable.
    }
  }

  Future<Map<String, dynamic>?> _tryGetMap(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await apiClient.get(
        path,
        headers: headers,
        expectedStatusCodes: const {200},
      );
      if (response == null) {
        return null;
      }

      return _expectMap(response, path);
    } on ApiException catch (exception) {
      if (exception.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  Future<String?> _resolveCompanyName({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/employees',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      if (response is! List) {
        return null;
      }

      for (final entry in response) {
        if (entry is! Map<String, dynamic>) {
          continue;
        }

        if ('${entry['userId']}' == userId) {
          final merchantName = entry['merchantName'];
          if (merchantName is String && merchantName.trim().isNotEmpty) {
            return merchantName.trim();
          }
        }
      }
    } on AppException {
      return null;
    }

    return null;
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
    };
  }

  Map<String, dynamic> _expectMap(Object? value, String source) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw AuthException('Respuesta inesperada del servidor.');
  }

  String _expectString(Object? value, String fieldName) {
    final normalized = '$value'.trim();
    if (normalized.isEmpty || normalized == 'null') {
      throw AuthException('Unexpected empty $fieldName in backend response.');
    }

    return normalized;
  }

  int _toInt(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      throw AuthException('Unexpected numeric value received from backend.');
    }

    return parsed;
  }
}
