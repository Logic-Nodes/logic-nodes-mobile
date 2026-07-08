import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/data/models/home_dashboard_model.dart';
import '../../domain/entities/analytics_trip.dart';

class RemoteAnalyticsDatasource {
  RemoteAnalyticsDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<AnalyticsDashboardPayload> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) async {
    final headers = _authHeaders(accessToken);

    final results = await Future.wait<Object?>([
      apiClient.get('/api/v1/trips', headers: headers, expectedStatusCodes: const {200}),
      apiClient.get('/api/v1/alerts', headers: headers, expectedStatusCodes: const {200}),
      apiClient.get('/api/v1/fleet/vehicles', headers: headers, expectedStatusCodes: const {200}),
      apiClient.get('/api/v1/fleet/devices', headers: headers, expectedStatusCodes: const {200}),
      apiClient.get(
        '/api/v1/monitoring/sessions/active',
        headers: headers,
        expectedStatusCodes: const {200},
      ),
      apiClient.get(
        '/api/v1/analytics/incidents-by-month',
        headers: headers,
        expectedStatusCodes: const {200},
      ),
      isFleetManager
          ? apiClient.get('/api/v1/employees', headers: headers, expectedStatusCodes: const {200})
          : Future<Object?>.value(const []),
      _safeGet('/api/v1/analytics/trips', headers),
      _safeGet('/api/v1/analytics/alerts', headers),
    ]);

    final allTrips = _parseTrips(results[0]);
    final allAlerts = _parseAlerts(results[1]);
    final allVehicles = _parseVehicles(results[2]);
    final allDevices = _parseDevices(results[3]);
    final activeSessions = _parseSessions(results[4]);
    final incidentsRaw = _expectList(results[5], 'incidents by month');
    final employeeRows = _expectList(results[6], 'employees');
    final analyticsTripsSummary = _asMap(results[7]);
    final analyticsAlertsSummary = _asMap(results[8]);

    final merchantId = isFleetManager
        ? _resolveMerchantId(employees: employeeRows, userId: userId)
        : null;
    final relevantTrips = _filterTrips(
      trips: allTrips,
      email: email,
      isFleetManager: isFleetManager,
      merchantId: merchantId,
    );
    final deliveryOrderIds = relevantTrips
        .expand((trip) => trip.deliveryOrders)
        .map((order) => order.id)
        .toSet();
    final relevantAlerts = allAlerts
        .where(
          (alert) =>
              alert.deliveryOrderId != null &&
              deliveryOrderIds.contains(alert.deliveryOrderId),
        )
        .toList(growable: false);
    final relevantVehicleIds = relevantTrips
        .map((trip) => trip.vehicleId)
        .whereType<String>()
        .toSet();
    final relevantVehicles = isFleetManager
        ? allVehicles
        : allVehicles
            .where((vehicle) => relevantVehicleIds.contains(vehicle.id))
            .toList(growable: false);
    final relevantVehiclePlates =
        relevantVehicles.map((vehicle) => vehicle.plate).toSet();
    final relevantDevices = isFleetManager
        ? allDevices
        : allDevices
            .where(
              (device) =>
                  device.vehiclePlate != null &&
                  relevantVehiclePlates.contains(device.vehiclePlate),
            )
            .toList(growable: false);
    final relevantTripIds = relevantTrips.map((trip) => trip.id).toSet();
    final relevantSessions = activeSessions
        .where((session) => relevantTripIds.contains(session.tripId))
        .toList(growable: false);

    final liveTelemetry = await _loadLatestTelemetry(
      accessToken: accessToken,
      sessions: relevantSessions.take(8).toList(growable: false),
      devices: relevantDevices,
    );

    return AnalyticsDashboardPayload(
      trips: relevantTrips,
      alerts: relevantAlerts,
      vehicles: relevantVehicles,
      devices: relevantDevices,
      activeSessions: relevantSessions,
      incidentsRaw: incidentsRaw,
      analyticsTripsSummary: analyticsTripsSummary,
      analyticsAlertsSummary: analyticsAlertsSummary,
      liveTelemetry: liveTelemetry,
      loadedAt: DateTime.now(),
    );
  }

  Future<TripDetailPayload> getTripDetail({
    required String accessToken,
    required String tripId,
  }) async {
    final headers = _authHeaders(accessToken);

    final results = await Future.wait<Object?>([
      apiClient.get(
        '/api/v1/trips/$tripId',
        headers: headers,
        expectedStatusCodes: const {200, 404},
      ),
      apiClient.get(
        '/api/v1/alerts',
        headers: headers,
        expectedStatusCodes: const {200},
      ),
      apiClient.get(
        '/api/v1/fleet/vehicles',
        headers: headers,
        expectedStatusCodes: const {200},
      ),
      apiClient.get(
        '/api/v1/monitoring/sessions/trip/$tripId',
        headers: headers,
        expectedStatusCodes: const {200},
      ),
    ]);

    final tripMap = results[0];
    if (tripMap == null) {
      throw AppException('Viaje no encontrado.');
    }

    final trip = HomeTripModel.fromMap(_expectMap(tripMap, 'trip'));
    final alerts = _parseAlerts(results[1]);
    final vehicles = _parseVehicles(results[2]);
    final sessions = _parseSessions(results[3]);
    final deliveryOrderIds =
        trip.deliveryOrders.map((order) => order.id).toSet();
    final tripAlerts = alerts
        .where(
          (alert) =>
              alert.deliveryOrderId != null &&
              deliveryOrderIds.contains(alert.deliveryOrderId),
        )
        .toList(growable: false);

    final telemetry = await _loadTelemetryForSessions(
      accessToken: accessToken,
      sessionIds: sessions.map((session) => session.id).toList(growable: false),
    );

    return TripDetailPayload(
      trip: trip,
      alerts: tripAlerts,
      vehicles: vehicles,
      telemetry: telemetry,
    );
  }

  Future<List<TelemetryRecordModel>> _loadTelemetryForSessions({
    required String accessToken,
    required List<String> sessionIds,
  }) async {
    if (sessionIds.isEmpty) {
      return const [];
    }

    final headers = _authHeaders(accessToken);
    final responses = await Future.wait<Object?>(
      sessionIds.map(
        (sessionId) => _safeGet('/api/v1/telemetry/session/$sessionId', headers),
      ),
    );

    final records = <TelemetryRecordModel>[];
    for (final response in responses) {
      records.addAll(_parseTelemetry(response));
    }

    records.sort(
      (left, right) => left.recordedAt.compareTo(right.recordedAt),
    );
    return records;
  }

  Future<List<LiveTelemetryReadingModel>> _loadLatestTelemetry({
    required String accessToken,
    required List<HomeMonitoringSessionModel> sessions,
    required List<HomeDeviceModel> devices,
  }) async {
    if (sessions.isEmpty) {
      return const [];
    }

    final headers = _authHeaders(accessToken);
    final deviceById = {
      for (final device in devices) device.id: device,
    };

    final readings = <LiveTelemetryReadingModel>[];
    for (final session in sessions) {
      final response = await _safeGet(
        '/api/v1/telemetry/session/${session.id}',
        headers,
      );
      final records = _parseTelemetry(response);
      if (records.isEmpty) {
        continue;
      }

      final latest = records.last;
      final device = deviceById[session.deviceId];
      readings.add(
        LiveTelemetryReadingModel(
          sessionId: session.id,
          deviceId: session.deviceId,
          tripId: session.tripId,
          temperature: latest.temperature,
          vibration: latest.vibration,
          vehiclePlate: device?.vehiclePlate ?? session.deviceId,
          recordedAt: latest.recordedAt,
        ),
      );
    }

    return readings;
  }

  Future<Object?> _safeGet(String path, Map<String, String> headers) async {
    try {
      return await apiClient.get(
        path,
        headers: headers,
        expectedStatusCodes: const {200},
      );
    } on AppException {
      return null;
    }
  }

  List<HomeTripModel> _filterTrips({
    required List<HomeTripModel> trips,
    required String email,
    required bool isFleetManager,
    required String? merchantId,
  }) {
    if (isFleetManager && merchantId != null) {
      return trips
          .where((trip) => trip.merchantId == merchantId)
          .toList(growable: false);
    }

    if (!isFleetManager) {
      final normalizedEmail = email.trim().toLowerCase();
      return trips
          .where(
            (trip) => trip.deliveryOrders.any(
              (order) =>
                  order.clientEmail.trim().toLowerCase() == normalizedEmail,
            ),
          )
          .toList(growable: false);
    }

    return trips;
  }

  String? _resolveMerchantId({
    required List<Object?> employees,
    required String userId,
  }) {
    for (final row in employees) {
      if (row is! Map<String, dynamic>) {
        continue;
      }
      if ('${row['userId']}' == userId) {
        final merchantId = '${row['merchantId']}'.trim();
        if (merchantId.isNotEmpty && merchantId != 'null') {
          return merchantId;
        }
      }
    }
    return null;
  }

  List<HomeTripModel> _parseTrips(Object? response) {
    return _expectList(response, 'trips')
        .whereType<Map<String, dynamic>>()
        .map(HomeTripModel.fromMap)
        .toList(growable: false);
  }

  List<HomeAlertModel> _parseAlerts(Object? response) {
    return _expectList(response, 'alerts')
        .whereType<Map<String, dynamic>>()
        .map(HomeAlertModel.fromMap)
        .toList(growable: false);
  }

  List<HomeVehicleModel> _parseVehicles(Object? response) {
    return _expectList(response, 'vehicles')
        .whereType<Map<String, dynamic>>()
        .map(HomeVehicleModel.fromMap)
        .toList(growable: false);
  }

  List<HomeDeviceModel> _parseDevices(Object? response) {
    return _expectList(response, 'devices')
        .whereType<Map<String, dynamic>>()
        .map(HomeDeviceModel.fromMap)
        .toList(growable: false);
  }

  List<HomeMonitoringSessionModel> _parseSessions(Object? response) {
    return _expectList(response, 'monitoring sessions')
        .whereType<Map<String, dynamic>>()
        .map(HomeMonitoringSessionModel.fromMap)
        .toList(growable: false);
  }

  List<TelemetryRecordModel> _parseTelemetry(Object? response) {
    return _expectList(response, 'telemetry')
        .whereType<Map<String, dynamic>>()
        .map(TelemetryRecordModel.fromMap)
        .toList(growable: false);
  }

  List<Object?> _expectList(Object? value, String source) {
    if (value is List) {
      return value.cast<Object?>();
    }
    throw AppException('Respuesta inesperada del servidor.');
  }

  Map<String, dynamic> _expectMap(Object? value, String source) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw AppException('Respuesta inesperada del servidor.');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const {};
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }
}

class AnalyticsDashboardPayload {
  const AnalyticsDashboardPayload({
    required this.trips,
    required this.alerts,
    required this.vehicles,
    required this.devices,
    required this.activeSessions,
    required this.incidentsRaw,
    required this.analyticsTripsSummary,
    required this.analyticsAlertsSummary,
    required this.liveTelemetry,
    required this.loadedAt,
  });

  final List<HomeTripModel> trips;
  final List<HomeAlertModel> alerts;
  final List<HomeVehicleModel> vehicles;
  final List<HomeDeviceModel> devices;
  final List<HomeMonitoringSessionModel> activeSessions;
  final List<Object?> incidentsRaw;
  final Map<String, dynamic> analyticsTripsSummary;
  final Map<String, dynamic> analyticsAlertsSummary;
  final List<LiveTelemetryReadingModel> liveTelemetry;
  final DateTime loadedAt;
}

class TripDetailPayload {
  const TripDetailPayload({
    required this.trip,
    required this.alerts,
    required this.vehicles,
    required this.telemetry,
  });

  final HomeTripModel trip;
  final List<HomeAlertModel> alerts;
  final List<HomeVehicleModel> vehicles;
  final List<TelemetryRecordModel> telemetry;
}

class TelemetryRecordModel {
  const TelemetryRecordModel({
    required this.id,
    required this.sessionId,
    required this.temperature,
    required this.vibration,
    required this.recordedAt,
  });

  factory TelemetryRecordModel.fromMap(Map<String, dynamic> map) {
    return TelemetryRecordModel(
      id: '${map['id']}',
      sessionId: '${map['monitoringSessionId'] ?? map['sessionId'] ?? ''}',
      temperature: map['temperature'] is num ? map['temperature'] as num : null,
      vibration: map['vibration'] is num ? map['vibration'] as num : null,
      recordedAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ??
          DateTime.tryParse('${map['insertedAt'] ?? ''}') ??
          DateTime.now(),
    );
  }

  final String id;
  final String sessionId;
  final num? temperature;
  final num? vibration;
  final DateTime recordedAt;

  TelemetryRecord toDomain() {
    return TelemetryRecord(
      id: id,
      sessionId: sessionId,
      temperature: temperature,
      vibration: vibration,
      recordedAt: recordedAt,
    );
  }
}

class LiveTelemetryReadingModel {
  const LiveTelemetryReadingModel({
    required this.sessionId,
    required this.deviceId,
    required this.tripId,
    required this.temperature,
    required this.vibration,
    required this.vehiclePlate,
    required this.recordedAt,
  });

  final String sessionId;
  final String deviceId;
  final String tripId;
  final num? temperature;
  final num? vibration;
  final String vehiclePlate;
  final DateTime recordedAt;

  LiveTelemetryReading toDomain() {
    return LiveTelemetryReading(
      sessionId: sessionId,
      deviceId: deviceId,
      tripId: tripId,
      temperature: temperature,
      vibration: vibration,
      vehiclePlate: vehiclePlate,
      recordedAt: recordedAt,
    );
  }
}
