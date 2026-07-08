import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_helpers.dart';
import '../models/profile_model.dart';

class RemoteProfileDatasource {
  RemoteProfileDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<ProfileModel> getProfileByUserId({
    required String accessToken,
    required String userId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/profiles/user/$userId',
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return ProfileModel.fromMap(expectMap(response, 'profile'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<ProfileModel> updateProfile({
    required String accessToken,
    required String profileId,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    try {
      final response = await apiClient.put(
        '/api/v1/profiles/$profileId',
        headers: authHeaders(accessToken),
        body: {
          'firstName': firstName,
          'lastName': lastName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
        expectedStatusCodes: const {200},
      );

      return ProfileModel.fromMap(expectMap(response, 'profile'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }
}
