import '../../../../core/storage/offline_cache_runner.dart';
import '../../../../core/storage/offline_cache_store.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/alert_repository.dart';
import '../models/alert_list_codec.dart';
import 'remote_alert_repository.dart';

class CachingAlertRepository implements AlertRepository {
  CachingAlertRepository({
    required RemoteAlertRepository remote,
    required OfflineCacheRunner cacheRunner,
    required this.userIdResolver,
  })  : _remote = remote,
        _cacheRunner = cacheRunner;

  final RemoteAlertRepository _remote;
  final OfflineCacheRunner _cacheRunner;
  final String? Function() userIdResolver;

  bool lastLoadUsedCache = false;

  String? get _userId => userIdResolver();

  @override
  Future<List<Alert>> listAlerts({
    required String accessToken,
  }) async {
    lastLoadUsedCache = false;
    final userId = _userId;
    if (userId == null) {
      return _remote.listAlerts(accessToken: accessToken);
    }

    try {
      final alerts = await _cacheRunner.run(
        cacheKey: OfflineCacheKeys.alerts(userId),
        remote: () => _remote.listAlerts(accessToken: accessToken),
        encode: AlertListCodec.encode,
        decode: AlertListCodec.decode,
      );
      return alerts;
    } on Object {
      rethrow;
    }
  }

  @override
  Future<List<Alert>> listAlertsByType({
    required String accessToken,
    required String type,
  }) {
    return _remote.listAlertsByType(accessToken: accessToken, type: type);
  }

  @override
  Future<List<Alert>> listAlertsByStatus({
    required String accessToken,
    required String status,
  }) {
    return _remote.listAlertsByStatus(accessToken: accessToken, status: status);
  }

  @override
  Future<Alert> getAlert({
    required String accessToken,
    required String alertId,
  }) {
    return _remote.getAlert(accessToken: accessToken, alertId: alertId);
  }

  @override
  Future<List<Incident>> listIncidentsByAlert({
    required String accessToken,
    required String alertId,
  }) {
    return _remote.listIncidentsByAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
  }

  @override
  Future<List<AlertNotification>> listNotificationsByAlert({
    required String accessToken,
    required String alertId,
  }) {
    return _remote.listNotificationsByAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
  }

  @override
  Future<Alert> resolveAlert({
    required String accessToken,
    required String alertId,
  }) {
    return _remote.resolveAlert(accessToken: accessToken, alertId: alertId);
  }

  @override
  Future<Alert> acknowledgeAlert({
    required String accessToken,
    required String alertId,
  }) {
    return _remote.acknowledgeAlert(
      accessToken: accessToken,
      alertId: alertId,
    );
  }
}
