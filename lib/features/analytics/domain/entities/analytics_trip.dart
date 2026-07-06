class AnalyticsTrip {
  const AnalyticsTrip({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.origin,
    required this.destination,
    required this.vehiclePlate,
    required this.driverName,
    required this.cargoType,
    required this.status,
    required this.distance,
    required this.alerts,
    this.vehicleId,
    this.driverId,
    this.deviceId,
    this.deliveryOrderIds = const [],
  });

  final String id;
  final String startDate;
  final String endDate;
  final String origin;
  final String destination;
  final String vehiclePlate;
  final String driverName;
  final String cargoType;
  final String status;
  final num distance;
  final List<String> alerts;
  final String? vehicleId;
  final String? driverId;
  final String? deviceId;
  final List<String> deliveryOrderIds;
}

class AnalyticsAlertPoint {
  const AnalyticsAlertPoint({
    required this.id,
    required this.tripId,
    required this.deviceId,
    required this.vehiclePlate,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.resolved,
    this.value,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String id;
  final String tripId;
  final String deviceId;
  final String vehiclePlate;
  final String type;
  final String severity;
  final String timestamp;
  final bool resolved;
  final num? value;
  final num? latitude;
  final num? longitude;
  final String? address;
}

class IncidentsByMonth {
  const IncidentsByMonth({
    required this.id,
    required this.month,
    required this.year,
    required this.temperatureIncidents,
    required this.movementIncidents,
    required this.totalIncidents,
  });

  final int id;
  final String month;
  final int year;
  final int temperatureIncidents;
  final int movementIncidents;
  final int totalIncidents;
}

class LiveTelemetryReading {
  const LiveTelemetryReading({
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
}

class FleetStatusSummary {
  const FleetStatusSummary({
    required this.inService,
    required this.maintenance,
    required this.outOfService,
  });

  final int inService;
  final int maintenance;
  final int outOfService;
}

class AnalyticsDashboard {
  const AnalyticsDashboard({
    required this.trips,
    required this.alerts,
    required this.incidentsByMonth,
    required this.liveTelemetry,
    required this.fleetStatus,
    required this.onlineDevices,
    required this.totalDevices,
    required this.activeSessions,
    required this.loadedAt,
  });

  final List<AnalyticsTrip> trips;
  final List<AnalyticsAlertPoint> alerts;
  final List<IncidentsByMonth> incidentsByMonth;
  final List<LiveTelemetryReading> liveTelemetry;
  final FleetStatusSummary fleetStatus;
  final int onlineDevices;
  final int totalDevices;
  final int activeSessions;
  final DateTime loadedAt;

  int get totalTrips => trips.length;
  int get activeTrips =>
      trips.where((trip) => trip.status.toUpperCase() == 'IN_PROGRESS').length;
  int get totalAlerts => alerts.length;
  int get pendingAlerts => alerts.where((alert) => !alert.resolved).length;
}

class TripAnalyticsDetail {
  const TripAnalyticsDetail({
    required this.trip,
    required this.alerts,
    required this.telemetry,
  });

  final AnalyticsTrip trip;
  final List<AnalyticsAlertPoint> alerts;
  final List<TelemetryRecord> telemetry;
}

class TelemetryRecord {
  const TelemetryRecord({
    required this.id,
    required this.sessionId,
    required this.temperature,
    required this.vibration,
    required this.recordedAt,
  });

  final String id;
  final String sessionId;
  final num? temperature;
  final num? vibration;
  final DateTime recordedAt;
}
