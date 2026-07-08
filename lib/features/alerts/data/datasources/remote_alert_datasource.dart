import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_helpers.dart';
import '../models/alert_model.dart';
import '../models/incident_model.dart';
import '../models/notification_model.dart';

class RemoteAlertDatasource {
  RemoteAlertDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<AlertModel>> listAlerts({
    required String accessToken,
  }) async {
    return _listAlertsFromPath(
      accessToken: accessToken,
      path: '/api/v1/alerts',
      source: 'alerts',
    );
  }

  Future<List<AlertModel>> listAlertsByType({
    required String accessToken,
    required String type,
  }) async {
    return _listAlertsFromPath(
      accessToken: accessToken,
      path: '/api/v1/alerts/type/$type',
      source: 'alerts by type',
    );
  }

  Future<List<AlertModel>> listAlertsByStatus({
    required String accessToken,
    required String status,
  }) async {
    return _listAlertsFromPath(
      accessToken: accessToken,
      path: '/api/v1/alerts/status/$status',
      source: 'alerts by status',
    );
  }

  Future<AlertModel> getAlert({
    required String accessToken,
    required String alertId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/alerts/$alertId',
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return AlertModel.fromMap(expectMap(response, 'alert'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<List<IncidentModel>> listIncidentsByAlert({
    required String accessToken,
    required String alertId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/incidents/alert/$alertId',
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return expectList(response, 'incidents')
          .whereType<Map<String, dynamic>>()
          .map(IncidentModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<List<NotificationModel>> listNotificationsByAlert({
    required String accessToken,
    required String alertId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/v1/notifications/alert/$alertId',
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return expectList(response, 'notifications')
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromMap)
          .toList(growable: false);
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
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      return AlertModel.fromMap(expectMap(response, 'alert'));
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<List<AlertModel>> _listAlertsFromPath({
    required String accessToken,
    required String path,
    required String source,
  }) async {
    try {
      final response = await apiClient.get(
        path,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );

      final rows = expectList(response, source);
      return rows
          .whereType<Map<String, dynamic>>()
          .map(AlertModel.fromMap)
          .toList(growable: false);
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }
}
