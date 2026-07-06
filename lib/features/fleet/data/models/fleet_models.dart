import '../../../../core/utils/json_parse.dart';
import '../../domain/entities/fleet_device.dart';
import '../../domain/entities/fleet_vehicle.dart';

class FleetVehicleModel {
  const FleetVehicleModel({
    required this.id,
    required this.plate,
    required this.type,
    required this.status,
    required this.deviceImeis,
    this.odometerKm,
  });

  factory FleetVehicleModel.fromMap(Map<String, dynamic> map) {
    final rawDeviceImeis = map['deviceImeis'];

    return FleetVehicleModel(
      id: _stringValue(map['id']),
      plate: _stringValue(map['plate']),
      type: _stringValue(map['type']).toUpperCase(),
      status: _stringValue(map['status']).toUpperCase(),
      odometerKm: nullableNumValue(map['odometerKm']),
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

  Map<String, dynamic> toCreatePayload() {
    return {
      'plate': plate,
      'type': type,
      'status': status,
      'odometerKm': odometerKm,
    };
  }

  Map<String, dynamic> toUpdatePayload() => toCreatePayload();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plate': plate,
      'type': type,
      'status': status,
      'odometerKm': odometerKm,
      'deviceImeis': deviceImeis,
    };
  }

  FleetVehicle toDomain() {
    return FleetVehicle(
      id: id,
      plate: plate,
      type: type,
      status: status,
      odometerKm: odometerKm,
      deviceImeis: deviceImeis,
    );
  }
}

class FleetDeviceModel {
  const FleetDeviceModel({
    required this.id,
    required this.imei,
    required this.online,
    this.vehiclePlate,
    this.firmware,
  });

  factory FleetDeviceModel.fromMap(Map<String, dynamic> map) {
    return FleetDeviceModel(
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

  Map<String, dynamic> toCreatePayload() {
    return {
      'imei': imei,
      'firmware': firmware,
      'online': online,
    };
  }

  Map<String, dynamic> toUpdatePayload() => toCreatePayload();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imei': imei,
      'online': online,
      'vehiclePlate': vehiclePlate,
      'firmware': firmware,
    };
  }

  FleetDevice toDomain() {
    return FleetDevice(
      id: id,
      imei: imei,
      online: online,
      vehiclePlate: vehiclePlate,
      firmware: firmware,
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
