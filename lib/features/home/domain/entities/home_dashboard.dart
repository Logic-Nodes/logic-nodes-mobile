class HomeDashboard {
  const HomeDashboard({
    required this.trips,
    required this.alerts,
    required this.vehicles,
    required this.devices,
    required this.activeSessions,
    required this.loadedAt,
    required this.scopeApplied,
    this.scopeNotice,
  });

  final List<HomeTrip> trips;
  final List<HomeAlert> alerts;
  final List<HomeVehicle> vehicles;
  final List<HomeDevice> devices;
  final List<HomeMonitoringSession> activeSessions;
  final DateTime loadedAt;
  final bool scopeApplied;
  final String? scopeNotice;

  int get totalTrips => trips.length;
  int get plannedTrips =>
      trips.where((trip) => trip.status == 'PLANNED').length;
  int get activeTrips =>
      trips.where((trip) => trip.status == 'IN_PROGRESS').length;
  int get completedTrips =>
      trips.where((trip) => trip.status == 'COMPLETED').length;
  int get cancelledTrips =>
      trips.where((trip) => trip.status == 'CANCELLED').length;

  int get totalDeliveryOrders => trips.fold<int>(
        0,
        (count, trip) => count + trip.deliveryOrders.length,
      );

  int get deliveredOrders => trips.fold<int>(
        0,
        (count, trip) => count + trip.deliveredOrders,
      );

  int get pendingOrders => trips.fold<int>(
        0,
        (count, trip) => count + trip.pendingOrders,
      );

  int get failedOrders => trips.fold<int>(
        0,
        (count, trip) => count + trip.failedOrders,
      );

  int get totalAlerts => alerts.length;
  int get openAlerts =>
      alerts.where((alert) => alert.status == 'OPEN').length;
  int get acknowledgedAlerts =>
      alerts.where((alert) => alert.status == 'ACKNOWLEDGED').length;
  int get closedAlerts =>
      alerts.where((alert) => alert.status == 'CLOSED').length;

  int get onlineDevices => devices.where((device) => device.online).length;
  int get offlineDevices => devices.where((device) => !device.online).length;
  int get totalVehicles => vehicles.length;

  Set<String> get deliveryOrderIds => trips
      .expand((trip) => trip.deliveryOrders)
      .map((order) => order.id)
      .toSet();

  Map<String, int> get alertCountsByType {
    final counts = <String, int>{};
    for (final alert in alerts) {
      counts.update(alert.type, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class HomeTrip {
  const HomeTrip({
    required this.id,
    required this.status,
    required this.deliveryOrders,
    this.merchantId,
    this.driverId,
    this.deviceId,
    this.vehicleId,
    this.originPointName,
    this.originPointAddress,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String? merchantId;
  final String? driverId;
  final String? deviceId;
  final String? vehicleId;
  final String status;
  final String? originPointName;
  final String? originPointAddress;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<HomeDeliveryOrder> deliveryOrders;

  int get deliveredOrders => deliveryOrders
      .where((order) => order.status == 'DELIVERED')
      .length;

  int get pendingOrders =>
      deliveryOrders.where((order) => order.status == 'PENDING').length;

  int get failedOrders =>
      deliveryOrders.where((order) => order.status == 'FAILED').length;

  double get completionProgress {
    if (deliveryOrders.isEmpty) {
      return switch (status) {
        'COMPLETED' => 1,
        'IN_PROGRESS' => 0.6,
        'PLANNED' => 0.15,
        'CANCELLED' => 0,
        _ => 0.2,
      };
    }

    return deliveredOrders / deliveryOrders.length;
  }

  DateTime? get lastActivityAt =>
      completedAt ?? startedAt ?? createdAt ?? deliveryOrdersLastUpdateAt;

  DateTime? get deliveryOrdersLastUpdateAt {
    final ordered = deliveryOrders
        .map((order) => order.lastActivityAt)
        .whereType<DateTime>()
        .toList()
      ..sort((left, right) => right.compareTo(left));

    return ordered.isEmpty ? null : ordered.first;
  }

  bool containsClientEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return deliveryOrders.any(
      (order) => order.clientEmail.trim().toLowerCase() == normalized,
    );
  }
}

class HomeDeliveryOrder {
  const HomeDeliveryOrder({
    required this.id,
    required this.clientEmail,
    required this.sequenceOrder,
    required this.status,
    this.arrivalAt,
    this.createdAt,
    this.address,
  });

  final String id;
  final String clientEmail;
  final int sequenceOrder;
  final String status;
  final DateTime? arrivalAt;
  final DateTime? createdAt;
  final String? address;

  DateTime? get lastActivityAt => arrivalAt ?? createdAt;
}

class HomeAlert {
  const HomeAlert({
    required this.id,
    required this.type,
    required this.status,
    this.deliveryOrderId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? deliveryOrderId;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get lastActivityAt => updatedAt ?? createdAt;
}

class HomeVehicle {
  const HomeVehicle({
    required this.id,
    required this.plate,
    required this.type,
    required this.status,
    required this.deviceImeis,
    this.odometerKm,
  });

  final String id;
  final String plate;
  final String type;
  final String status;
  final num? odometerKm;
  final List<String> deviceImeis;
}

class HomeDevice {
  const HomeDevice({
    required this.id,
    required this.imei,
    required this.online,
    this.vehiclePlate,
    this.firmware,
  });

  final String id;
  final String imei;
  final bool online;
  final String? vehiclePlate;
  final String? firmware;
}

class HomeMonitoringSession {
  const HomeMonitoringSession({
    required this.id,
    required this.tripId,
    required this.deviceId,
    required this.status,
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String deviceId;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? createdAt;
}
