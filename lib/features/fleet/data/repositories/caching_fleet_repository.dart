import '../../../../core/storage/offline_cache_runner.dart';
import '../../../../core/storage/offline_cache_store.dart';
import '../../domain/entities/fleet_device.dart';
import '../../domain/entities/fleet_vehicle.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../models/fleet_list_codec.dart';
import 'remote_fleet_repository.dart';

class CachingFleetRepository implements FleetRepository {
  CachingFleetRepository({
    required RemoteFleetRepository remote,
    required OfflineCacheRunner cacheRunner,
    required this.userIdResolver,
  })  : _remote = remote,
        _cacheRunner = cacheRunner;

  final RemoteFleetRepository _remote;
  final OfflineCacheRunner _cacheRunner;
  final String? Function() userIdResolver;

  bool lastListUsedCache = false;

  String? get _userId => userIdResolver();

  @override
  Future<List<FleetVehicle>> listVehicles({
    required String accessToken,
  }) async {
    lastListUsedCache = false;
    final userId = _userId;
    if (userId == null) {
      return _remote.listVehicles(accessToken: accessToken);
    }

    return _cacheRunner.run(
      cacheKey: OfflineCacheKeys.vehicles(userId),
      remote: () => _remote.listVehicles(accessToken: accessToken),
      encode: FleetListCodec.encodeVehicles,
      decode: FleetListCodec.decodeVehicles,
    );
  }

  @override
  Future<List<FleetDevice>> listDevices({
    required String accessToken,
  }) async {
    lastListUsedCache = false;
    final userId = _userId;
    if (userId == null) {
      return _remote.listDevices(accessToken: accessToken);
    }

    return _cacheRunner.run(
      cacheKey: OfflineCacheKeys.devices(userId),
      remote: () => _remote.listDevices(accessToken: accessToken),
      encode: FleetListCodec.encodeDevices,
      decode: FleetListCodec.decodeDevices,
    );
  }

  @override
  Future<FleetVehicle> getVehicle({
    required String accessToken,
    required String vehicleId,
  }) {
    return _remote.getVehicle(accessToken: accessToken, vehicleId: vehicleId);
  }

  @override
  Future<FleetVehicle> createVehicle({
    required String accessToken,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) {
    return _remote.createVehicle(
      accessToken: accessToken,
      plate: plate,
      type: type,
      status: status,
      odometerKm: odometerKm,
    );
  }

  @override
  Future<FleetVehicle> updateVehicle({
    required String accessToken,
    required String vehicleId,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) {
    return _remote.updateVehicle(
      accessToken: accessToken,
      vehicleId: vehicleId,
      plate: plate,
      type: type,
      status: status,
      odometerKm: odometerKm,
    );
  }

  @override
  Future<void> deleteVehicle({
    required String accessToken,
    required String vehicleId,
  }) {
    return _remote.deleteVehicle(
      accessToken: accessToken,
      vehicleId: vehicleId,
    );
  }

  @override
  Future<FleetVehicle> updateVehicleStatus({
    required String accessToken,
    required String vehicleId,
    required String status,
  }) {
    return _remote.updateVehicleStatus(
      accessToken: accessToken,
      vehicleId: vehicleId,
      status: status,
    );
  }

  @override
  Future<FleetVehicle> assignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) {
    return _remote.assignDevice(
      accessToken: accessToken,
      vehicleId: vehicleId,
      imei: imei,
    );
  }

  @override
  Future<FleetVehicle> unassignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) {
    return _remote.unassignDevice(
      accessToken: accessToken,
      vehicleId: vehicleId,
      imei: imei,
    );
  }

  @override
  Future<FleetDevice> getDevice({
    required String accessToken,
    required String deviceId,
  }) {
    return _remote.getDevice(accessToken: accessToken, deviceId: deviceId);
  }

  @override
  Future<FleetDevice> createDevice({
    required String accessToken,
    required String imei,
    String? firmware,
    bool online = false,
  }) {
    return _remote.createDevice(
      accessToken: accessToken,
      imei: imei,
      firmware: firmware,
      online: online,
    );
  }

  @override
  Future<FleetDevice> updateDevice({
    required String accessToken,
    required String deviceId,
    required String imei,
    String? firmware,
    required bool online,
  }) {
    return _remote.updateDevice(
      accessToken: accessToken,
      deviceId: deviceId,
      imei: imei,
      firmware: firmware,
      online: online,
    );
  }

  @override
  Future<void> deleteDevice({
    required String accessToken,
    required String deviceId,
  }) {
    return _remote.deleteDevice(accessToken: accessToken, deviceId: deviceId);
  }

  @override
  Future<FleetDevice> updateDeviceOnline({
    required String accessToken,
    required String deviceId,
    required bool online,
  }) {
    return _remote.updateDeviceOnline(
      accessToken: accessToken,
      deviceId: deviceId,
      online: online,
    );
  }

  @override
  Future<FleetDevice> updateDeviceFirmware({
    required String accessToken,
    required String deviceId,
    required String firmware,
  }) {
    return _remote.updateDeviceFirmware(
      accessToken: accessToken,
      deviceId: deviceId,
      firmware: firmware,
    );
  }
}
