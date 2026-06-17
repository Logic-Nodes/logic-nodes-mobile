import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/alert_model.dart';

class RemoteAlertDatasource {
  RemoteAlertDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<AlertModel>> listAlerts({
    required String accessToken,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/alerts',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      final rows = _expectList(response, 'alerts');
      return rows
          .whereType<Map<String, dynamic>>()
          .map(AlertModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<AlertModel> getAlert({
    required String accessToken,
    required String alertId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/alerts/$alertId',
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return AlertModel.fromMap(_expectMap(response, 'alert'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<AlertModel> resolveAlert({
    required String accessToken,
    required String alertId,
  }) async {
    return _patchStatus(
      accessToken: accessToken,
      path: '/api/v1/alerts/$alertId/closure',
    );
  }

  Future<AlertModel> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  }) async {
    return _patchStatus(
      accessToken: accessToken,
      path: '/api/v1/alerts/$alertId/acknowledgment',
    );
  }

  Future<AlertModel> _patchStatus({
    required String accessToken,
    required String path,
  }) async {
    try {
      final response = await apiClient.patch(
        path,
        headers: _authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return AlertModel.fromMap(_expectMap(response, 'alert'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
    };
  }

  List<Object?> _expectList(Object? value, String source) {
    if (value is List) {
      return value.cast<Object?>();
    }

    throw AppException('Unexpected response received from $source.');
  }

  Map<String, dynamic> _expectMap(Object? value, String source) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw AppException('Unexpected response received from $source.');
  }
}
