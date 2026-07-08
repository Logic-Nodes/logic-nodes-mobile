import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../models/auth_session_model.dart';

class MockAuthDatasource {
  MockAuthDatasource();

  final List<_DemoAccount> _accounts = [
    _DemoAccount(
      id: 'usr-fleet-001',
      name: 'Elena Vasquez',
      email: 'fleet@omnitrack.io',
      password: 'Fleet123!',
      role: UserRole.fleetManager,
      companyName: 'North Coast Logistics',
    ),
    _DemoAccount(
      id: 'usr-client-001',
      name: 'Ana Torres',
      email: 'client@omnitrack.io',
      password: 'Client123!',
      role: UserRole.customer,
      companyName: 'Organic Market Peru',
    ),
  ];

  Future<AuthSessionModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));

    final account = _accounts
        .where(
          (candidate) => candidate.email.toLowerCase() == email.toLowerCase(),
        )
        .firstOrNull;

    if (account == null || account.password != password) {
      throw const AuthException(
        'No se pudo autenticar. Revisa tus credenciales e inténtalo de nuevo.',
      );
    }

    return AuthSessionModel(
      accessToken: 'mock-access-${account.id}',
      refreshToken: 'mock-refresh-${account.id}',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
      user: AuthUserModel(
        id: account.id,
        name: account.name,
        email: account.email,
        role: account.role,
        companyName: account.companyName,
      ),
    );
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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _ensureEmailIsUnique(companyContactEmail);
    _ensureEmailIsUnique(adminEmail);

    _accounts.add(
      _DemoAccount(
        id: 'usr-company-${_accounts.length + 1}',
        name: '$adminFirstName $adminLastName',
        email: adminEmail,
        password: password,
        role: UserRole.fleetManager,
        companyName: legalName,
      ),
    );
  }

  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _ensureEmailIsUnique(email);

    _accounts.add(
      _DemoAccount(
        id: 'usr-client-${_accounts.length + 1}',
        name: '$firstName $lastName',
        email: email,
        password: password,
        role: UserRole.customer,
      ),
    );
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final exists = _accounts.any(
      (candidate) => candidate.email.toLowerCase() == email.toLowerCase(),
    );

    if (!exists) {
      throw const AuthException(
        'No hay ninguna cuenta asociada a ese correo.',
      );
    }
  }

  Future<void> resetPassword({
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (password.length < 8) {
      throw const AuthException(
        'La nueva contraseña debe tener al menos 8 caracteres.',
      );
    }
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  void _ensureEmailIsUnique(String email) {
    final alreadyExists = _accounts.any(
      (candidate) => candidate.email.toLowerCase() == email.toLowerCase(),
    );

    if (alreadyExists) {
      throw const AuthException(
        'Este correo ya está registrado en OmniTrack.',
      );
    }
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.companyName,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? companyName;
}
