import '../../../home/data/models/home_dashboard_model.dart';
import '../../domain/entities/analytics_trip.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/remote_analytics_datasource.dart';

class RemoteAnalyticsRepository implements AnalyticsRepository {
  RemoteAnalyticsRepository({
    required this.datasource,
  });

  final RemoteAnalyticsDatasource datasource;

  @override
  Future<AnalyticsDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) async {
    final payload = await datasource.loadDashboard(
      accessToken: accessToken,
      userId: userId,
      email: email,
      isFleetManager: isFleetManager,
    );

    final vehicleById = {
      for (final vehicle in payload.vehicles) vehicle.id: vehicle,
    };

    return AnalyticsDashboard(
      trips: payload.trips
          .map(
            (trip) => _mapTrip(
              trip: trip,
              vehicleById: vehicleById,
              alerts: payload.alerts,
            ),
          )
          .toList(growable: false),
      alerts: payload.alerts
          .map(
            (alert) => _mapAlert(
              alert: alert,
              trips: payload.trips,
              vehicleById: vehicleById,
            ),
          )
          .toList(growable: false),
      incidentsByMonth: _mapIncidents(
        payload.incidentsRaw,
        payload.alerts,
      ),
      liveTelemetry:
          payload.liveTelemetry.map((item) => item.toDomain()).toList(growable: false),
      fleetStatus: FleetStatusSummary(
        inService: payload.vehicles
            .where((vehicle) => vehicle.status == 'IN_SERVICE')
            .length,
        maintenance: payload.vehicles
            .where((vehicle) => vehicle.status == 'MAINTENANCE')
            .length,
        outOfService: payload.vehicles
            .where((vehicle) => vehicle.status == 'OUT_OF_SERVICE')
            .length,
      ),
      onlineDevices: payload.devices.where((device) => device.online).length,
      totalDevices: payload.devices.length,
      activeSessions: payload.activeSessions.length,
      loadedAt: payload.loadedAt,
    );
  }

  @override
  Future<TripAnalyticsDetail> getTripDetail({
    required String accessToken,
    required String tripId,
  }) async {
    final payload = await datasource.getTripDetail(
      accessToken: accessToken,
      tripId: tripId,
    );

    final vehicleById = {
      for (final vehicle in payload.vehicles) vehicle.id: vehicle,
    };

    return TripAnalyticsDetail(
      trip: _mapTrip(
        trip: payload.trip,
        vehicleById: vehicleById,
        alerts: payload.alerts,
      ),
      alerts: payload.alerts
          .map(
            (alert) => _mapAlert(
              alert: alert,
              trips: [payload.trip],
              vehicleById: vehicleById,
              tripId: payload.trip.id,
            ),
          )
          .toList(growable: false),
      telemetry: payload.telemetry.map((item) => item.toDomain()).toList(growable: false),
    );
  }

  AnalyticsTrip _mapTrip({
    required HomeTripModel trip,
    required Map<String, HomeVehicleModel> vehicleById,
    required List<HomeAlertModel> alerts,
  }) {
    final vehicle = trip.vehicleId != null ? vehicleById[trip.vehicleId!] : null;
    final deliveryOrderIds =
        trip.deliveryOrders.map((order) => order.id).toList(growable: false);
    final tripAlertIds = alerts
        .where(
          (alert) =>
              alert.deliveryOrderId != null &&
              deliveryOrderIds.contains(alert.deliveryOrderId),
        )
        .map((alert) => alert.id)
        .toList(growable: false);

    final destination = trip.deliveryOrders.isEmpty
        ? '--'
        : trip.deliveryOrders.last.address ??
            'Order #${trip.deliveryOrders.last.id}';

    return AnalyticsTrip(
      id: trip.id,
      startDate: _formatDate(trip.startedAt ?? trip.createdAt),
      endDate: _formatDate(trip.completedAt),
      origin: trip.originPointName ?? trip.originPointAddress ?? '--',
      destination: destination,
      vehiclePlate: vehicle?.plate ?? trip.vehicleId ?? '--',
      driverName: trip.driverId == null ? '--' : 'Driver ${trip.driverId}',
      cargoType: trip.deliveryOrders.isEmpty
          ? 'General cargo'
          : '${trip.deliveryOrders.length} orders',
      status: trip.status,
      distance: 0,
      alerts: tripAlertIds,
      vehicleId: trip.vehicleId,
      driverId: trip.driverId,
      deviceId: trip.deviceId,
      deliveryOrderIds: deliveryOrderIds,
    );
  }

  AnalyticsAlertPoint _mapAlert({
    required HomeAlertModel alert,
    required List<HomeTripModel> trips,
    required Map<String, HomeVehicleModel> vehicleById,
    String? tripId,
  }) {
    final linkedTrip = trips.firstWhere(
      (trip) => trip.deliveryOrders.any((order) => order.id == alert.deliveryOrderId),
      orElse: () => trips.isNotEmpty ? trips.first : const HomeTripModel(
        id: '--',
        status: '--',
        deliveryOrders: [],
      ),
    );
    final vehicle =
        linkedTrip.vehicleId != null ? vehicleById[linkedTrip.vehicleId!] : null;
    final resolved = alert.status == 'CLOSED' || alert.status == 'RESOLVED';

    return AnalyticsAlertPoint(
      id: alert.id,
      tripId: tripId ?? linkedTrip.id,
      deviceId: linkedTrip.deviceId ?? '--',
      vehiclePlate: vehicle?.plate ?? linkedTrip.vehicleId ?? '--',
      type: alert.type,
      severity: alert.status,
      timestamp: (alert.createdAt ?? alert.updatedAt ?? DateTime.now())
          .toIso8601String(),
      resolved: resolved,
    );
  }

  List<IncidentsByMonth> _mapIncidents(
    List<Object?> incidentsRaw,
    List<HomeAlertModel> alerts,
  ) {
    if (incidentsRaw.isNotEmpty) {
      return incidentsRaw.asMap().entries.map((entry) {
        final map = entry.value;
        if (map is! Map<String, dynamic>) {
          return IncidentsByMonth(
            id: entry.key,
            month: '--',
            year: DateTime.now().year,
            temperatureIncidents: 0,
            movementIncidents: 0,
            totalIncidents: 0,
          );
        }

        final monthKey = '${map['month'] ?? ''}';
        final parts = monthKey.split('-');
        final year = parts.isNotEmpty ? int.tryParse(parts.first) ?? DateTime.now().year : DateTime.now().year;
        final monthNumber = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
        final monthLabel = _monthLabel(monthNumber);
        final total = map['count'] is num ? (map['count'] as num).toInt() : 0;

        return IncidentsByMonth(
          id: entry.key,
          month: monthLabel,
          year: year,
          temperatureIncidents: 0,
          movementIncidents: 0,
          totalIncidents: total,
        );
      }).toList(growable: false);
    }

    return _incidentsFromAlerts(alerts);
  }

  List<IncidentsByMonth> _incidentsFromAlerts(List<HomeAlertModel> alerts) {
    final grouped = <String, List<HomeAlertModel>>{};
    for (final alert in alerts) {
      final timestamp = alert.createdAt ?? alert.updatedAt ?? DateTime.now();
      final key =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(alert);
    }

    final entries = grouped.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final groupAlerts = mapEntry.value;
      final parts = mapEntry.key.split('-');
      final year = int.tryParse(parts.first) ?? DateTime.now().year;
      final monthNumber = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
      final temperature = groupAlerts
          .where((alert) => alert.type.contains('TEMP'))
          .length;
      final movement = groupAlerts
          .where((alert) => alert.type.contains('MOV') || alert.type.contains('VIB'))
          .length;

      return IncidentsByMonth(
        id: index,
        month: _monthLabel(monthNumber),
        year: year,
        temperatureIncidents: temperature,
        movementIncidents: movement,
        totalIncidents: groupAlerts.length,
      );
    }).toList(growable: false);
  }

  String _monthLabel(int month) {
    const labels = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month < 1 || month > 12) {
      return 'Unknown';
    }
    return labels[month - 1];
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '--';
    }
    return value.toIso8601String();
  }
}
