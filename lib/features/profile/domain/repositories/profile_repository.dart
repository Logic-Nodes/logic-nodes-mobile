import '../../domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfileByUserId({
    required String accessToken,
    required String userId,
  });

  Future<UserProfile> updateProfile({
    required String accessToken,
    required String profileId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });
}
