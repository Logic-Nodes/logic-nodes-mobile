import '../entities/alert.dart';

abstract class AlertRepository {
  Future<List<Alert>> listAlerts({
    required String accessToken,
  });

  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  });

  Future<Alert> resolveAlert({
    required String accessToken,
    required String alertId,
  });

  Future<Alert> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  });
}
