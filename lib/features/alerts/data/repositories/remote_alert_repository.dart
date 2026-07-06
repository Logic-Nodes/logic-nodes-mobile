import '../../domain/entities/alert.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/remote_alert_datasource.dart';

class RemoteAlertRepository implements AlertRepository {
  const RemoteAlertRepository({
    required this.datasource,
  });

  final RemoteAlertDatasource datasource;

  @override
  Future<List<Alert>> listAlerts({
    required String accessToken,
  }) async {
    final models = await datasource.listAlerts(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<List<Alert>> listAlertsByType({
    required String accessToken,
    required String type,
  }) async {
    final models = await datasource.listAlertsByType(
      accessToken: accessToken,
      type: type,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<List<Alert>> listAlertsByStatus({
    required String accessToken,
    required String status,
  }) async {
    final models = await datasource.listAlertsByStatus(
      accessToken: accessToken,
      status: status,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  }) async {
    final model = await datasource.getAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
    return model.toDomain();
  }

  @override
  Future<List<Incident>> listIncidentsByAlert({
    required String accessToken,
    required String alertId,
  }) async {
    final models = await datasource.listIncidentsByAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<List<AlertNotification>> listNotificationsByAlert({
    required String accessToken,
    required String alertId,
  }) async {
    final models = await datasource.listNotificationsByAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<Alert> resolveAlert({
    required String accessToken,
    required String alertId,
  }) async {
    final model = await datasource.resolveAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
    return model.toDomain();
  }

  @override
  Future<Alert> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  }) async {
    final model = await datasource.acknowledgeAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
    return model.toDomain();
  }
}
