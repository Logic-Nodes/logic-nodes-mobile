class UserProfile {
  const UserProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  String get fullName => '$firstName $lastName'.trim();
}
