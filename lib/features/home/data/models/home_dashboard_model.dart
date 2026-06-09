import '../../domain/entities/home_dashboard.dart';

class HomeDashboardModel {
  const HomeDashboardModel({
    required this.trips,
    required this.alerts,
    required this.vehicles,
    required this.devices,
    required this.activeSessions,
    required this.loadedAt,
    required this.scopeApplied,
    this.scopeNotice,
  });

  final List<HomeTripModel> trips;
  final List<HomeAlertModel> alerts;
  final List<HomeVehicleModel> vehicles;
  final List<HomeDeviceModel> devices;
  final List<HomeMonitoringSessionModel> activeSessions;
  final DateTime loadedAt;
  final bool scopeApplied;
  final String? scopeNotice;

  HomeDashboard toDomain() {
    return HomeDashboard(
      trips: trips.map((trip) => trip.toDomain()).toList(growable: false),
      alerts: alerts.map((alert) => alert.toDomain()).toList(growable: false),
      vehicles:
          vehicles.map((vehicle) => vehicle.toDomain()).toList(growable: false),
      devices: devices.map((device) => device.toDomain()).toList(growable: false),
      activeSessions: activeSessions
          .map((session) => session.toDomain())
          .toList(growable: false),
      loadedAt: loadedAt,
      scopeApplied: scopeApplied,
      scopeNotice: scopeNotice,
    );
  }
}

class HomeTripModel {
  const HomeTripModel({
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

  factory HomeTripModel.fromMap(Map<String, dynamic> map) {
    final rawOriginPoint = map['originPoint'];
    final originPoint = rawOriginPoint is Map<String, dynamic>
        ? rawOriginPoint
        : <String, dynamic>{};
    final rawOrders = map['deliveryOrders'];

    return HomeTripModel(
      id: _stringValue(map['id']),
      merchantId: _nullableStringValue(map['merchantId']),
      driverId: _nullableStringValue(map['driverId']),
      deviceId: _nullableStringValue(map['deviceId']),
      vehicleId: _nullableStringValue(map['vehicleId']),
      status: _stringValue(map['status']).toUpperCase(),
      originPointName: _nullableStringValue(originPoint['name']),
      originPointAddress: _nullableStringValue(originPoint['address']),
      createdAt: _dateValue(map['createdAt']),
      startedAt: _dateValue(map['startedAt']),
      completedAt: _dateValue(map['completedAt']),
      deliveryOrders: rawOrders is List
          ? rawOrders
              .whereType<Map<String, dynamic>>()
              .map(HomeDeliveryOrderModel.fromMap)
              .toList(growable: false)
          : const [],
    );
  }

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
  final List<HomeDeliveryOrderModel> deliveryOrders;

  HomeTrip toDomain() {
    return HomeTrip(
      id: id,
      merchantId: merchantId,
      driverId: driverId,
      deviceId: deviceId,
      vehicleId: vehicleId,
      status: status,
      originPointName: originPointName,
      originPointAddress: originPointAddress,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      deliveryOrders:
          deliveryOrders.map((order) => order.toDomain()).toList(growable: false),
    );
  }
}

class HomeDeliveryOrderModel {
  const HomeDeliveryOrderModel({
    required this.id,
    required this.clientEmail,
    required this.sequenceOrder,
    required this.status,
    this.arrivalAt,
    this.createdAt,
    this.address,
  });

  factory HomeDeliveryOrderModel.fromMap(Map<String, dynamic> map) {
    return HomeDeliveryOrderModel(
      id: _stringValue(map['id']),
      clientEmail: _stringValue(map['clientEmail']),
      sequenceOrder: _intValue(map['sequenceOrder']),
      status: _stringValue(map['status']).toUpperCase(),
      arrivalAt: _dateValue(map['arrivalAt']),
      createdAt: _dateValue(map['createdAt']),
      address: _nullableStringValue(map['address']),
    );
  }

  final String id;
  final String clientEmail;
  final int sequenceOrder;
  final String status;
  final DateTime? arrivalAt;
  final DateTime? createdAt;
  final String? address;

  HomeDeliveryOrder toDomain() {
    return HomeDeliveryOrder(
      id: id,
      clientEmail: clientEmail,
      sequenceOrder: sequenceOrder,
      status: status,
      arrivalAt: arrivalAt,
      createdAt: createdAt,
      address: address,
    );
  }
}

class HomeAlertModel {
  const HomeAlertModel({
    required this.id,
    required this.type,
    required this.status,
    this.deliveryOrderId,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeAlertModel.fromMap(Map<String, dynamic> map) {
    return HomeAlertModel(
      id: _stringValue(map['id']),
      deliveryOrderId: _nullableStringValue(map['deliveryOrderId']),
      type: _stringValue(map['alertType']).toUpperCase(),
      status: _stringValue(map['alertStatus']).toUpperCase(),
      createdAt: _dateValue(map['createdAt']),
      updatedAt: _dateValue(map['updatedAt']),
    );
  }

  final String id;
  final String? deliveryOrderId;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeAlert toDomain() {
    return HomeAlert(
      id: id,
      deliveryOrderId: deliveryOrderId,
      type: type,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class HomeVehicleModel {
  const HomeVehicleModel({
    required this.id,
    required this.plate,
    required this.type,
    required this.status,
    required this.deviceImeis,
    this.odometerKm,
  });

  factory HomeVehicleModel.fromMap(Map<String, dynamic> map) {
    final rawDeviceImeis = map['deviceImeis'];

    return HomeVehicleModel(
      id: _stringValue(map['id']),
      plate: _stringValue(map['plate']),
      type: _stringValue(map['type']).toUpperCase(),
      status: _stringValue(map['status']).toUpperCase(),
      odometerKm: map['odometerKm'] as num?,
      deviceImeis: rawDeviceImeis is List
          ? rawDeviceImeis
              .map((value) => _nullableStringValue(value))
              .whereType<String>()
              .toList(growable: false)
          : const [],
    );
  }

  final String id;
  final String plate;
  final String type;
  final String status;
  final num? odometerKm;
  final List<String> deviceImeis;

  HomeVehicle toDomain() {
    return HomeVehicle(
      id: id,
      plate: plate,
      type: type,
      status: status,
      odometerKm: odometerKm,
      deviceImeis: deviceImeis,
    );
  }
}

class HomeDeviceModel {
  const HomeDeviceModel({
    required this.id,
    required this.imei,
    required this.online,
    this.vehiclePlate,
    this.firmware,
  });

  factory HomeDeviceModel.fromMap(Map<String, dynamic> map) {
    return HomeDeviceModel(
      id: _stringValue(map['id']),
      imei: _stringValue(map['imei']),
      online: map['online'] == true,
      vehiclePlate: _nullableStringValue(map['vehiclePlate']),
      firmware: _nullableStringValue(map['firmware']),
    );
  }

  final String id;
  final String imei;
  final bool online;
  final String? vehiclePlate;
  final String? firmware;

  HomeDevice toDomain() {
    return HomeDevice(
      id: id,
      imei: imei,
      online: online,
      vehiclePlate: vehiclePlate,
      firmware: firmware,
    );
  }
}

class HomeMonitoringSessionModel {
  const HomeMonitoringSessionModel({
    required this.id,
    required this.tripId,
    required this.deviceId,
    required this.status,
    this.startTime,
    this.endTime,
    this.createdAt,
  });

  factory HomeMonitoringSessionModel.fromMap(Map<String, dynamic> map) {
    return HomeMonitoringSessionModel(
      id: _stringValue(map['id']),
      tripId: _stringValue(map['tripId']),
      deviceId: _stringValue(map['deviceId']),
      status: _stringValue(map['status']).toUpperCase(),
      startTime: _dateValue(map['startTime']),
      endTime: _dateValue(map['endTime']),
      createdAt: _dateValue(map['createdAt']),
    );
  }

  final String id;
  final String tripId;
  final String deviceId;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? createdAt;

  HomeMonitoringSession toDomain() {
    return HomeMonitoringSession(
      id: id,
      tripId: tripId,
      deviceId: deviceId,
      status: status,
      startTime: startTime,
      endTime: endTime,
      createdAt: createdAt,
    );
  }
}

String _stringValue(Object? value) => '$value'.trim();

String? _nullableStringValue(Object? value) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return null;
  }

  return normalized;
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

DateTime? _dateValue(Object? value) {
  final raw = _nullableStringValue(value);
  if (raw == null) {
    return null;
  }

  return DateTime.tryParse(raw);
}
