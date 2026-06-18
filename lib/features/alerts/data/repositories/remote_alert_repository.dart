import '../../domain/entities/alert.dart';
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
