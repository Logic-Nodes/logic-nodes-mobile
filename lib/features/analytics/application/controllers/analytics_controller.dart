import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/entities/analytics_trip.dart';
import '../../domain/repositories/analytics_repository.dart';

enum AnalyticsPeriod {
  threeMonths('3m', 3),
  sixMonths('6m', 6),
  twelveMonths('12m', 12);

  const AnalyticsPeriod(this.label, this.monthCount);

  final String label;
  final int monthCount;
}

enum AnalyticsAlertTypeFilter {
  all('All'),
  temperature('Temperature'),
  movement('Movement');

  const AnalyticsAlertTypeFilter(this.label);

  final String label;
}

class IncidentsChartPoint {
  const IncidentsChartPoint({
    required this.label,
    required this.temperature,
    required this.movement,
    required this.total,
  });

  final String label;
  final double temperature;
  final double movement;
  final double total;
}

class SensorChartPoint {
  const SensorChartPoint({
    required this.time,
    required this.value,
    required this.timestamp,
  });

  final String time;
  final double value;
  final DateTime timestamp;
}

class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required this.analyticsRepository,
    required this.sessionController,
  });

  final AnalyticsRepository analyticsRepository;
  final SessionController sessionController;

  AnalyticsDashboard? _dashboard;
  TripAnalyticsDetail? _tripDetail;
  bool _isLoading = false;
  bool _isLoadingTrip = false;
  String? _errorMessage;
  AnalyticsPeriod _period = AnalyticsPeriod.twelveMonths;
  AnalyticsAlertTypeFilter _alertTypeFilter = AnalyticsAlertTypeFilter.all;

  AnalyticsDashboard? get dashboard => _dashboard;
  TripAnalyticsDetail? get tripDetail => _tripDetail;
  AnalyticsTrip? get selectedTrip => _tripDetail?.trip;
  List<AnalyticsAlertPoint> get tripAlerts => _tripDetail?.alerts ?? const [];
  bool get isLoading => _isLoading;
  bool get isLoadingTrip => _isLoadingTrip;
  String? get errorMessage => _errorMessage;
  AnalyticsPeriod get period => _period;
  AnalyticsAlertTypeFilter get alertTypeFilter => _alertTypeFilter;

  List<IncidentsChartPoint> get chartData {
    final incidents = _dashboard?.incidentsByMonth ?? const [];
    if (incidents.isEmpty) {
      return const [];
    }

    final filtered = incidents.length <= _period.monthCount
        ? incidents
        : incidents.sublist(incidents.length - _period.monthCount);

    return filtered
        .map(
          (incident) {
            final hasSplit =
                incident.temperatureIncidents > 0 || incident.movementIncidents > 0;
            final temperature = hasSplit
                ? incident.temperatureIncidents.toDouble()
                : incident.totalIncidents.toDouble();
            final movement = hasSplit
                ? incident.movementIncidents.toDouble()
                : 0.0;

            return IncidentsChartPoint(
              label: '${incident.month.substring(0, 3)} ${incident.year}',
              temperature: _alertTypeFilter == AnalyticsAlertTypeFilter.movement
                  ? 0
                  : temperature,
              movement: _alertTypeFilter == AnalyticsAlertTypeFilter.temperature
                  ? 0
                  : movement,
              total: incident.totalIncidents.toDouble(),
            );
          },
        )
        .toList(growable: false);
  }

  List<SensorChartPoint> get temperatureSeries {
    final telemetry = _tripDetail?.telemetry ?? const [];
    return telemetry
        .where((record) => record.temperature != null)
        .map(
          (record) => SensorChartPoint(
            time: _formatTime(record.recordedAt),
            value: record.temperature!.toDouble(),
            timestamp: record.recordedAt,
          ),
        )
        .toList(growable: false);
  }

  List<SensorChartPoint> get vibrationSeries {
    final telemetry = _tripDetail?.telemetry ?? const [];
    return telemetry
        .where((record) => record.vibration != null)
        .map(
          (record) => SensorChartPoint(
            time: _formatTime(record.recordedAt),
            value: record.vibration!.toDouble(),
            timestamp: record.recordedAt,
          ),
        )
        .toList(growable: false);
  }

  void changePeriod(AnalyticsPeriod value) {
    if (value == _period) {
      return;
    }
    _period = value;
    notifyListeners();
  }

  void changeAlertTypeFilter(AnalyticsAlertTypeFilter value) {
    if (value == _alertTypeFilter) {
      return;
    }
    _alertTypeFilter = value;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    final session = sessionController.session;
    if (session == null || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboard = await analyticsRepository.loadDashboard(
        accessToken: session.accessToken,
        userId: session.user.id,
        email: session.user.email,
        isFleetManager: session.user.role == UserRole.fleetManager,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'Unable to load analytics from the current backend.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTripDetail(String tripId) async {
    final session = sessionController.session;
    if (session == null || _isLoadingTrip) {
      return;
    }

    _isLoadingTrip = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tripDetail = await analyticsRepository.getTripDetail(
        accessToken: session.accessToken,
        tripId: tripId,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      _tripDetail = null;
    } on Exception {
      _errorMessage = 'Unable to load trip analytics from the backend.';
      _tripDetail = null;
    } finally {
      _isLoadingTrip = false;
      notifyListeners();
    }
  }

  String _formatTime(DateTime timestamp) {
    final hours = timestamp.hour.toString().padLeft(2, '0');
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
