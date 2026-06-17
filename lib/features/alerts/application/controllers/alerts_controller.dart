import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';

enum AlertStatusFilter {
  all,
  open,
  acknowledged,
  resolved;

  String get label {
    switch (this) {
      case AlertStatusFilter.all:
        return 'All';
      case AlertStatusFilter.open:
        return 'Open';
      case AlertStatusFilter.acknowledged:
        return 'Acknowledged';
      case AlertStatusFilter.resolved:
        return 'Resolved';
    }
  }

  bool matches(Alert alert) {
    switch (this) {
      case AlertStatusFilter.all:
        return true;
      case AlertStatusFilter.open:
        return alert.status == AlertStatus.open;
      case AlertStatusFilter.acknowledged:
        return alert.status == AlertStatus.acknowledged;
      case AlertStatusFilter.resolved:
        return alert.status == AlertStatus.closed;
    }
  }
}

class AlertsController extends ChangeNotifier {
  AlertsController({
    required this.alertRepository,
    required this.sessionController,
  });

  final AlertRepository alertRepository;
  final SessionController sessionController;

  List<Alert> _alerts = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  AlertStatusFilter _statusFilter = AlertStatusFilter.all;
  final Set<String> _resolvingIds = <String>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  AlertStatusFilter get statusFilter => _statusFilter;

  int get openCount =>
      _alerts.where((alert) => alert.status == AlertStatus.open).length;
  int get acknowledgedCount =>
      _alerts.where((alert) => alert.status == AlertStatus.acknowledged).length;
  int get resolvedCount =>
      _alerts.where((alert) => alert.status == AlertStatus.closed).length;

  bool isResolving(String alertId) => _resolvingIds.contains(alertId);

  Alert allAlertById(String alertId) {
    return _alerts.firstWhere(
      (alert) => alert.id == alertId,
      orElse: () => Alert(
        id: alertId,
        type: 'OTHER',
        status: AlertStatus.open,
      ),
    );
  }

  List<Alert> get visibleAlerts {
    final query = _searchQuery.trim().toLowerCase();
    return _alerts.where((alert) {
      if (!_statusFilter.matches(alert)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return alert.typeLabel.toLowerCase().contains(query) ||
          alert.id.toLowerCase().contains(query) ||
          (alert.deliveryOrderId?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  void search(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void changeFilter(AlertStatusFilter filter) {
    if (filter == _statusFilter) {
      return;
    }

    _statusFilter = filter;
    notifyListeners();
  }

  Future<void> load() async {
    final session = sessionController.session;
    if (session == null || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _alerts = await alertRepository.listAlerts(
        accessToken: session.accessToken,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'Unable to load alerts from the current backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resolve(String alertId) async {
    final session = sessionController.session;
    if (session == null || _resolvingIds.contains(alertId)) {
      return false;
    }

    _resolvingIds.add(alertId);
    notifyListeners();

    try {
      final updated = await alertRepository.resolveAlert(
        accessToken: session.accessToken,
        alertId: alertId,
      );
      _replaceAlert(updated);
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _resolvingIds.remove(alertId);
      notifyListeners();
    }
  }

  void _replaceAlert(Alert updated) {
    _alerts = _alerts
        .map((alert) => alert.id == updated.id ? updated : alert)
        .toList(growable: false);
  }
}
