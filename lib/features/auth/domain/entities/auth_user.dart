enum UserRole {
  fleetManager('Fleet Manager'),
  customer('Customer');

  const UserRole(this.label);

  final String label;
}

class AuthUser {
  const AuthUser({
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
}
