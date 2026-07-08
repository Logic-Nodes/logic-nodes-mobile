import '../../../../core/network/api_helpers.dart';
import '../../domain/entities/profile.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: stringValue(map['id']),
      userId: stringValue(map['userId']),
      firstName: stringValue(map['firstName']),
      lastName: stringValue(map['lastName']),
      phoneNumber: nullableStringValue(map['phoneNumber']),
    );
  }

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
  }

  Map<String, dynamic> toUpdateJson({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) {
    return {
      'firstName': firstName,
      'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}
