import 'dart:convert';

import '../../../../core/utils/json_parse.dart';
import '../../../home/domain/entities/home_dashboard.dart';

class HomeDashboardCodec {
  static String encode(HomeDashboard dashboard) {
    return jsonEncode(_toMap(dashboard));
  }

  static HomeDashboard decode(String payload) {
    final map = jsonDecode(payload);
    if (map is! Map<String, dynamic>) {
      throw const FormatException('Invalid dashboard cache payload.');
    }

    return _fromMap(map);
  }

  static Map<String, dynamic> _toMap(HomeDashboard dashboard) {
    return {
      'loadedAt': dashboard.loadedAt.toUtc().toIso8601String(),
      'scopeApplied': dashboard.scopeApplied,
      'scopeNotice': dashboard.scopeNotice,
      'isFromCache': dashboard.isFromCache,
      'trips': dashboard.trips.map(_tripToMap).toList(growable: false),
      'alerts': dashboard.alerts.map(_alertToMap).toList(growable: false),
      'vehicles': dashboard.vehicles.map(_vehicleToMap).toList(growable: false),
      'devices': dashboard.devices.map(_deviceToMap).toList(growable: false),
      'activeSessions':
          dashboard.activeSessions.map(_sessionToMap).toList(growable: false),
    };
  }

  static HomeDashboard _fromMap(Map<String, dynamic> map) {
    return HomeDashboard(
      loadedAt: DateTime.parse(map['loadedAt'] as String).toLocal(),
      scopeApplied: map['scopeApplied'] == true,
      scopeNotice: map['scopeNotice'] as String?,
      isFromCache: map['isFromCache'] == true,
      trips: _readList(map['trips'])
          .whereType<Map<String, dynamic>>()
          .map(_tripFromMap)
          .toList(growable: false),
      alerts: _readList(map['alerts'])
          .whereType<Map<String, dynamic>>()
          .map(_alertFromMap)
          .toList(growable: false),
      vehicles: _readList(map['vehicles'])
          .whereType<Map<String, dynamic>>()
          .map(_vehicleFromMap)
          .toList(growable: false),
      devices: _readList(map['devices'])
          .whereType<Map<String, dynamic>>()
          .map(_deviceFromMap)
          .toList(growable: false),
      activeSessions: _readList(map['activeSessions'])
          .whereType<Map<String, dynamic>>()
          .map(_sessionFromMap)
          .toList(growable: false),
    );
  }

  static List<dynamic> _readList(Object? value) {
    if (value is List) {
      return value;
    }

    return const [];
  }

  static Map<String, dynamic> _tripToMap(HomeTrip trip) {
    return {
      'id': trip.id,
      'merchantId': trip.merchantId,
      'driverId': trip.driverId,
      'deviceId': trip.deviceId,
      'vehicleId': trip.vehicleId,
      'status': trip.status,
      'originPointName': trip.originPointName,
      'originPointAddress': trip.originPointAddress,
      'createdAt': trip.createdAt?.toUtc().toIso8601String(),
      'startedAt': trip.startedAt?.toUtc().toIso8601String(),
      'completedAt': trip.completedAt?.toUtc().toIso8601String(),
      'deliveryOrders':
          trip.deliveryOrders.map(_deliveryOrderToMap).toList(growable: false),
    };
  }

  static HomeTrip _tripFromMap(Map<String, dynamic> map) {
    return HomeTrip(
      id: '${map['id']}',
      merchantId: map['merchantId'] as String?,
      driverId: map['driverId'] as String?,
      deviceId: map['deviceId'] as String?,
      vehicleId: map['vehicleId'] as String?,
      status: '${map['status']}',
      originPointName: map['originPointName'] as String?,
      originPointAddress: map['originPointAddress'] as String?,
      createdAt: _parseDate(map['createdAt']),
      startedAt: _parseDate(map['startedAt']),
      completedAt: _parseDate(map['completedAt']),
      deliveryOrders: _readList(map['deliveryOrders'])
          .whereType<Map<String, dynamic>>()
          .map(_deliveryOrderFromMap)
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _deliveryOrderToMap(HomeDeliveryOrder order) {
    return {
      'id': order.id,
      'clientEmail': order.clientEmail,
      'sequenceOrder': order.sequenceOrder,
      'status': order.status,
      'arrivalAt': order.arrivalAt?.toUtc().toIso8601String(),
      'createdAt': order.createdAt?.toUtc().toIso8601String(),
      'address': order.address,
    };
  }

  static HomeDeliveryOrder _deliveryOrderFromMap(Map<String, dynamic> map) {
    return HomeDeliveryOrder(
      id: '${map['id']}',
      clientEmail: '${map['clientEmail']}',
      sequenceOrder: map['sequenceOrder'] as int? ?? 0,
      status: '${map['status']}',
      arrivalAt: _parseDate(map['arrivalAt']),
      createdAt: _parseDate(map['createdAt']),
      address: map['address'] as String?,
    );
  }

  static Map<String, dynamic> _alertToMap(HomeAlert alert) {
    return {
      'id': alert.id,
      'deliveryOrderId': alert.deliveryOrderId,
      'type': alert.type,
      'status': alert.status,
      'createdAt': alert.createdAt?.toUtc().toIso8601String(),
      'updatedAt': alert.updatedAt?.toUtc().toIso8601String(),
    };
  }

  static HomeAlert _alertFromMap(Map<String, dynamic> map) {
    return HomeAlert(
      id: '${map['id']}',
      deliveryOrderId: map['deliveryOrderId'] as String?,
      type: '${map['type']}',
      status: '${map['status']}',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static Map<String, dynamic> _vehicleToMap(HomeVehicle vehicle) {
    return {
      'id': vehicle.id,
      'plate': vehicle.plate,
      'type': vehicle.type,
      'status': vehicle.status,
      'odometerKm': vehicle.odometerKm,
      'deviceImeis': vehicle.deviceImeis,
    };
  }

  static HomeVehicle _vehicleFromMap(Map<String, dynamic> map) {
    return HomeVehicle(
      id: '${map['id']}',
      plate: '${map['plate']}',
      type: '${map['type']}',
      status: '${map['status']}',
      odometerKm: nullableNumValue(map['odometerKm']),
      deviceImeis: _readList(map['deviceImeis'])
          .map((value) => '$value')
          .toList(growable: false),
    );
  }

  static Map<String, dynamic> _deviceToMap(HomeDevice device) {
    return {
      'id': device.id,
      'imei': device.imei,
      'online': device.online,
      'vehiclePlate': device.vehiclePlate,
      'firmware': device.firmware,
    };
  }

  static HomeDevice _deviceFromMap(Map<String, dynamic> map) {
    return HomeDevice(
      id: '${map['id']}',
      imei: '${map['imei']}',
      online: map['online'] == true,
      vehiclePlate: map['vehiclePlate'] as String?,
      firmware: map['firmware'] as String?,
    );
  }

  static Map<String, dynamic> _sessionToMap(HomeMonitoringSession session) {
    return {
      'id': session.id,
      'tripId': session.tripId,
      'deviceId': session.deviceId,
      'status': session.status,
      'startTime': session.startTime?.toUtc().toIso8601String(),
      'endTime': session.endTime?.toUtc().toIso8601String(),
      'createdAt': session.createdAt?.toUtc().toIso8601String(),
    };
  }

  static HomeMonitoringSession _sessionFromMap(Map<String, dynamic> map) {
    return HomeMonitoringSession(
      id: '${map['id']}',
      tripId: '${map['tripId']}',
      deviceId: '${map['deviceId']}',
      status: '${map['status']}',
      startTime: _parseDate(map['startTime']),
      endTime: _parseDate(map['endTime']),
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }

  static String encodeTrips(List<HomeTrip> trips) {
    return jsonEncode(trips.map(_tripToMap).toList(growable: false));
  }

  static List<HomeTrip> decodeTrips(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_tripFromMap)
        .toList(growable: false);
  }

  static String encodeAlerts(List<HomeAlert> alerts) {
    return jsonEncode(alerts.map(_alertToMap).toList(growable: false));
  }

  static List<HomeAlert> decodeAlerts(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_alertFromMap)
        .toList(growable: false);
  }
}
