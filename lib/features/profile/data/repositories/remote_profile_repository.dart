import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/remote_profile_datasource.dart';

class RemoteProfileRepository implements ProfileRepository {
  const RemoteProfileRepository({
    required this.datasource,
  });

  final RemoteProfileDatasource datasource;

  @override
  Future<UserProfile> getProfileByUserId({
    required String accessToken,
    required String userId,
  }) async {
    final model = await datasource.getProfileByUserId(
      accessToken: accessToken,
      userId: userId,
    );
    return model.toDomain();
  }

  @override
  Future<UserProfile> updateProfile({
    required String accessToken,
    required String profileId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final model = await datasource.updateProfile(
      accessToken: accessToken,
      profileId: profileId,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );
    return model.toDomain();
  }
}
