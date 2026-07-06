import '../entities/alert.dart';
import '../entities/incident.dart';
import '../entities/notification.dart';

abstract class AlertRepository {
  Future<List<Alert>> listAlerts({
    required String accessToken,
  });

  Future<List<Alert>> listAlertsByType({
    required String accessToken,
    required String type,
  });

  Future<List<Alert>> listAlertsByStatus({
    required String accessToken,
    required String status,
  });

  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  });

  Future<List<Incident>> listIncidentsByAlert({
    required String accessToken,
    required String alertId,
  });

  Future<List<AlertNotification>> listNotificationsByAlert({
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
