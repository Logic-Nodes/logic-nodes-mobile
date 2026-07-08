import 'dart:convert';

import '../../domain/entities/fleet_device.dart';
import '../../domain/entities/fleet_vehicle.dart';
import 'fleet_models.dart';

class FleetListCodec {
  static String encodeVehicles(List<FleetVehicle> vehicles) {
    return jsonEncode(
      vehicles
          .map(
            (vehicle) => FleetVehicleModel(
              id: vehicle.id,
              plate: vehicle.plate,
              type: vehicle.type,
              status: vehicle.status,
              odometerKm: vehicle.odometerKm,
              deviceImeis: vehicle.deviceImeis,
            ).toMap(),
          )
          .toList(growable: false),
    );
  }

  static List<FleetVehicle> decodeVehicles(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(FleetVehicleModel.fromMap)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  static String encodeDevices(List<FleetDevice> devices) {
    return jsonEncode(
      devices
          .map(
            (device) => FleetDeviceModel(
              id: device.id,
              imei: device.imei,
              online: device.online,
              vehiclePlate: device.vehiclePlate,
              firmware: device.firmware,
            ).toMap(),
          )
          .toList(growable: false),
    );
  }

  static List<FleetDevice> decodeDevices(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(FleetDeviceModel.fromMap)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }
}
