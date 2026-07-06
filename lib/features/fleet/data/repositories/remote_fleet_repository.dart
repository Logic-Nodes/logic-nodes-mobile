import '../../domain/entities/fleet_device.dart';
import '../../domain/entities/fleet_vehicle.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/remote_fleet_datasource.dart';
import '../models/fleet_models.dart';

class RemoteFleetRepository implements FleetRepository {
  const RemoteFleetRepository({
    required this.datasource,
  });

  final RemoteFleetDatasource datasource;

  @override
  Future<List<FleetVehicle>> listVehicles({
    required String accessToken,
  }) async {
    final models = await datasource.listVehicles(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<FleetVehicle> getVehicle({
    required String accessToken,
    required String vehicleId,
  }) async {
    final model = await datasource.getVehicle(
      accessToken: accessToken,
      vehicleId: vehicleId,
    );
    return model.toDomain();
  }

  @override
  Future<FleetVehicle> createVehicle({
    required String accessToken,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) async {
    final model = await datasource.createVehicle(
      accessToken: accessToken,
      payload: FleetVehicleModel(
        id: '',
        plate: plate,
        type: type,
        status: status,
        odometerKm: odometerKm,
        deviceImeis: const [],
      ),
    );
    return model.toDomain();
  }

  @override
  Future<FleetVehicle> updateVehicle({
    required String accessToken,
    required String vehicleId,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) async {
    final model = await datasource.updateVehicle(
      accessToken: accessToken,
      vehicleId: vehicleId,
      payload: FleetVehicleModel(
        id: vehicleId,
        plate: plate,
        type: type,
        status: status,
        odometerKm: odometerKm,
        deviceImeis: const [],
      ),
    );
    return model.toDomain();
  }

  @override
  Future<void> deleteVehicle({
    required String accessToken,
    required String vehicleId,
  }) {
    return datasource.deleteVehicle(
      accessToken: accessToken,
      vehicleId: vehicleId,
    );
  }

  @override
  Future<FleetVehicle> updateVehicleStatus({
    required String accessToken,
    required String vehicleId,
    required String status,
  }) async {
    final model = await datasource.updateVehicleStatus(
      accessToken: accessToken,
      vehicleId: vehicleId,
      status: status,
    );
    return model.toDomain();
  }

  @override
  Future<FleetVehicle> assignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) async {
    final model = await datasource.assignDevice(
      accessToken: accessToken,
      vehicleId: vehicleId,
      imei: imei,
    );
    return model.toDomain();
  }

  @override
  Future<FleetVehicle> unassignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) async {
    final model = await datasource.unassignDevice(
      accessToken: accessToken,
      vehicleId: vehicleId,
      imei: imei,
    );
    return model.toDomain();
  }

  @override
  Future<List<FleetDevice>> listDevices({
    required String accessToken,
  }) async {
    final models = await datasource.listDevices(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<FleetDevice> getDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    final model = await datasource.getDevice(
      accessToken: accessToken,
      deviceId: deviceId,
    );
    return model.toDomain();
  }

  @override
  Future<FleetDevice> createDevice({
    required String accessToken,
    required String imei,
    String? firmware,
    bool online = false,
  }) async {
    final model = await datasource.createDevice(
      accessToken: accessToken,
      payload: FleetDeviceModel(
        id: '',
        imei: imei,
        online: online,
        firmware: firmware,
      ),
    );
    return model.toDomain();
  }

  @override
  Future<FleetDevice> updateDevice({
    required String accessToken,
    required String deviceId,
    required String imei,
    String? firmware,
    required bool online,
  }) async {
    final model = await datasource.updateDevice(
      accessToken: accessToken,
      deviceId: deviceId,
      payload: FleetDeviceModel(
        id: deviceId,
        imei: imei,
        online: online,
        firmware: firmware,
      ),
    );
    return model.toDomain();
  }

  @override
  Future<void> deleteDevice({
    required String accessToken,
    required String deviceId,
  }) {
    return datasource.deleteDevice(
      accessToken: accessToken,
      deviceId: deviceId,
    );
  }

  @override
  Future<FleetDevice> updateDeviceOnline({
    required String accessToken,
    required String deviceId,
    required bool online,
  }) async {
    final model = await datasource.updateDeviceOnline(
      accessToken: accessToken,
      deviceId: deviceId,
      online: online,
    );
    return model.toDomain();
  }

  @override
  Future<FleetDevice> updateDeviceFirmware({
    required String accessToken,
    required String deviceId,
    required String firmware,
  }) async {
    final model = await datasource.updateDeviceFirmware(
      accessToken: accessToken,
      deviceId: deviceId,
      firmware: firmware,
    );
    return model.toDomain();
  }
}
