import '../entities/fleet_device.dart';
import '../entities/fleet_vehicle.dart';

abstract class FleetRepository {
  Future<List<FleetVehicle>> listVehicles({
    required String accessToken,
  });

  Future<FleetVehicle> getVehicle({
    required String accessToken,
    required String vehicleId,
  });

  Future<FleetVehicle> createVehicle({
    required String accessToken,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  });

  Future<FleetVehicle> updateVehicle({
    required String accessToken,
    required String vehicleId,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  });

  Future<void> deleteVehicle({
    required String accessToken,
    required String vehicleId,
  });

  Future<FleetVehicle> updateVehicleStatus({
    required String accessToken,
    required String vehicleId,
    required String status,
  });

  Future<FleetVehicle> assignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  });

  Future<FleetVehicle> unassignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  });

  Future<List<FleetDevice>> listDevices({
    required String accessToken,
  });

  Future<FleetDevice> getDevice({
    required String accessToken,
    required String deviceId,
  });

  Future<FleetDevice> createDevice({
    required String accessToken,
    required String imei,
    String? firmware,
    bool online = false,
  });

  Future<FleetDevice> updateDevice({
    required String accessToken,
    required String deviceId,
    required String imei,
    String? firmware,
    required bool online,
  });

  Future<void> deleteDevice({
    required String accessToken,
    required String deviceId,
  });

  Future<FleetDevice> updateDeviceOnline({
    required String accessToken,
    required String deviceId,
    required bool online,
  });

  Future<FleetDevice> updateDeviceFirmware({
    required String accessToken,
    required String deviceId,
    required String firmware,
  });
}
