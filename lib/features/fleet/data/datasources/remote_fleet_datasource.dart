import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_helpers.dart';
import '../models/fleet_models.dart';

class RemoteFleetDatasource {
  RemoteFleetDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<FleetVehicleModel>> listVehicles({
    required String accessToken,
  }) async {
    return _mapVehicleList(
      await _get('/api/v1/fleet/vehicles', accessToken, 'vehicles'),
    );
  }

  Future<FleetVehicleModel> getVehicle({
    required String accessToken,
    required String vehicleId,
  }) async {
    final response = await _get(
      '/api/v1/fleet/vehicles/$vehicleId',
      accessToken,
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<FleetVehicleModel> createVehicle({
    required String accessToken,
    required FleetVehicleModel payload,
  }) async {
    final response = await _post(
      '/api/v1/fleet/vehicles',
      accessToken,
      payload.toCreatePayload(),
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<FleetVehicleModel> updateVehicle({
    required String accessToken,
    required String vehicleId,
    required FleetVehicleModel payload,
  }) async {
    final response = await _put(
      '/api/v1/fleet/vehicles/$vehicleId',
      accessToken,
      payload.toUpdatePayload(),
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<void> deleteVehicle({
    required String accessToken,
    required String vehicleId,
  }) async {
    await _delete(
      '/api/v1/fleet/vehicles/$vehicleId',
      accessToken,
      'vehicle',
    );
  }

  Future<FleetVehicleModel> updateVehicleStatus({
    required String accessToken,
    required String vehicleId,
    required String status,
  }) async {
    final response = await _patch(
      '/api/v1/fleet/vehicles/$vehicleId/status',
      accessToken,
      {'status': status},
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<FleetVehicleModel> assignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) async {
    final response = await _post(
      '/api/v1/fleet/vehicles/$vehicleId/assign-device/$imei',
      accessToken,
      null,
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<FleetVehicleModel> unassignDevice({
    required String accessToken,
    required String vehicleId,
    required String imei,
  }) async {
    final response = await _post(
      '/api/v1/fleet/vehicles/$vehicleId/unassign-device/$imei',
      accessToken,
      null,
      'vehicle',
    );
    return FleetVehicleModel.fromMap(expectItem(response, 'vehicle'));
  }

  Future<List<FleetDeviceModel>> listDevices({
    required String accessToken,
  }) async {
    return _mapDeviceList(
      await _get('/api/v1/fleet/devices', accessToken, 'devices'),
    );
  }

  Future<FleetDeviceModel> getDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    final response = await _get(
      '/api/v1/fleet/devices/$deviceId',
      accessToken,
      'device',
    );
    return FleetDeviceModel.fromMap(expectItem(response, 'device'));
  }

  Future<FleetDeviceModel> createDevice({
    required String accessToken,
    required FleetDeviceModel payload,
  }) async {
    final response = await _post(
      '/api/v1/fleet/devices',
      accessToken,
      payload.toCreatePayload(),
      'device',
    );
    return FleetDeviceModel.fromMap(expectItem(response, 'device'));
  }

  Future<FleetDeviceModel> updateDevice({
    required String accessToken,
    required String deviceId,
    required FleetDeviceModel payload,
  }) async {
    final response = await _put(
      '/api/v1/fleet/devices/$deviceId',
      accessToken,
      payload.toUpdatePayload(),
      'device',
    );
    return FleetDeviceModel.fromMap(expectItem(response, 'device'));
  }

  Future<void> deleteDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    await _delete(
      '/api/v1/fleet/devices/$deviceId',
      accessToken,
      'device',
    );
  }

  Future<FleetDeviceModel> updateDeviceOnline({
    required String accessToken,
    required String deviceId,
    required bool online,
  }) async {
    final response = await _patch(
      '/api/v1/fleet/devices/$deviceId/online',
      accessToken,
      {'online': online},
      'device',
    );
    return FleetDeviceModel.fromMap(expectItem(response, 'device'));
  }

  Future<FleetDeviceModel> updateDeviceFirmware({
    required String accessToken,
    required String deviceId,
    required String firmware,
  }) async {
    final response = await _post(
      '/api/v1/fleet/devices/$deviceId/firmware',
      accessToken,
      {'firmware': firmware},
      'device',
    );
    return FleetDeviceModel.fromMap(expectItem(response, 'device'));
  }

  Future<Object?> _get(
    String path,
    String accessToken,
    String source,
  ) async {
    try {
      return await apiClient.get(
        path,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<Object?> _post(
    String path,
    String accessToken,
    Object? body,
    String source,
  ) async {
    try {
      return await apiClient.post(
        path,
        body: body,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200, 201},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<Object?> _put(
    String path,
    String accessToken,
    Object? body,
    String source,
  ) async {
    try {
      return await apiClient.put(
        path,
        body: body,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<Object?> _patch(
    String path,
    String accessToken,
    Object? body,
    String source,
  ) async {
    try {
      return await apiClient.patch(
        path,
        body: body,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<void> _delete(
    String path,
    String accessToken,
    String source,
  ) async {
    try {
      await apiClient.delete(
        path,
        headers: authHeaders(accessToken),
        expectedStatusCodes: const {200, 204},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  List<FleetVehicleModel> _mapVehicleList(Object? response) {
    return expectList(response, 'vehicles')
        .whereType<Map<String, dynamic>>()
        .map(FleetVehicleModel.fromMap)
        .toList(growable: false);
  }

  List<FleetDeviceModel> _mapDeviceList(Object? response) {
    return expectList(response, 'devices')
        .whereType<Map<String, dynamic>>()
        .map(FleetDeviceModel.fromMap)
        .toList(growable: false);
  }
}
