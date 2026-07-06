import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../domain/entities/fleet_device.dart';
import '../../domain/entities/fleet_vehicle.dart';
import '../../domain/repositories/fleet_repository.dart';

const fleetVehicleTypes = <String>[
  'TRUCK',
  'VAN',
  'CAR',
  'MOTORCYCLE',
];

const fleetVehicleStatuses = <String>[
  'IN_SERVICE',
  'MAINTENANCE',
  'OUT_OF_SERVICE',
];

class FleetController extends ChangeNotifier {
  FleetController({
    required this.fleetRepository,
    required this.sessionController,
  });

  final FleetRepository fleetRepository;
  final SessionController sessionController;

  List<FleetVehicle> _vehicles = const [];
  List<FleetDevice> _devices = const [];
  FleetVehicle? _selectedVehicle;
  FleetDevice? _selectedDevice;
  bool _isLoadingVehicles = false;
  bool _isLoadingDevices = false;
  bool _isLoadingVehicleDetail = false;
  bool _isLoadingDeviceDetail = false;
  bool _isSaving = false;
  String? _errorMessage;
  final Set<String> _busyVehicleIds = <String>{};
  final Set<String> _busyDeviceIds = <String>{};

  List<FleetVehicle> get vehicles => _vehicles;
  List<FleetDevice> get devices => _devices;
  FleetVehicle? get selectedVehicle => _selectedVehicle;
  FleetDevice? get selectedDevice => _selectedDevice;
  bool get isLoadingVehicles => _isLoadingVehicles;
  bool get isLoadingDevices => _isLoadingDevices;
  bool get isLoadingVehicleDetail => _isLoadingVehicleDetail;
  bool get isLoadingDeviceDetail => _isLoadingDeviceDetail;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get onlineDeviceCount => _devices.where((device) => device.online).length;
  int get inServiceVehicleCount =>
      _vehicles.where((vehicle) => vehicle.status == 'IN_SERVICE').length;

  bool isVehicleBusy(String vehicleId) => _busyVehicleIds.contains(vehicleId);
  bool isDeviceBusy(String deviceId) => _busyDeviceIds.contains(deviceId);

  List<FleetDevice> get unassignedDevices => _devices
      .where((device) => !device.isAssigned)
      .toList(growable: false);

  FleetVehicle vehicleById(String vehicleId) {
    if (_selectedVehicle?.id == vehicleId) {
      return _selectedVehicle!;
    }

    return _vehicles.firstWhere(
      (vehicle) => vehicle.id == vehicleId,
      orElse: () => FleetVehicle(
        id: vehicleId,
        plate: vehicleId,
        type: 'TRUCK',
        status: 'IN_SERVICE',
        deviceImeis: const [],
      ),
    );
  }

  FleetDevice deviceById(String deviceId) {
    if (_selectedDevice?.id == deviceId) {
      return _selectedDevice!;
    }

    return _devices.firstWhere(
      (device) => device.id == deviceId,
      orElse: () => FleetDevice(
        id: deviceId,
        imei: deviceId,
        online: false,
      ),
    );
  }

  Future<void> loadVehicles() async {
    final session = sessionController.session;
    if (session == null || _isLoadingVehicles) {
      return;
    }

    _isLoadingVehicles = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _vehicles = await fleetRepository.listVehicles(
        accessToken: session.accessToken,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudieron cargar los vehículos.';
    } finally {
      _isLoadingVehicles = false;
      notifyListeners();
    }
  }

  Future<void> loadDevices() async {
    final session = sessionController.session;
    if (session == null || _isLoadingDevices) {
      return;
    }

    _isLoadingDevices = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _devices = await fleetRepository.listDevices(
        accessToken: session.accessToken,
      );
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudieron cargar los dispositivos.';
    } finally {
      _isLoadingDevices = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    await Future.wait<void>([
      loadVehicles(),
      loadDevices(),
    ]);
  }

  Future<void> loadVehicleDetail(String vehicleId) async {
    final session = sessionController.session;
    if (session == null || _isLoadingVehicleDetail) {
      return;
    }

    _isLoadingVehicleDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedVehicle = await fleetRepository.getVehicle(
        accessToken: session.accessToken,
        vehicleId: vehicleId,
      );
      _replaceVehicle(_selectedVehicle!);
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudo cargar el detalle del vehículo.';
    } finally {
      _isLoadingVehicleDetail = false;
      notifyListeners();
    }
  }

  Future<void> loadDeviceDetail(String deviceId) async {
    final session = sessionController.session;
    if (session == null || _isLoadingDeviceDetail) {
      return;
    }

    _isLoadingDeviceDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedDevice = await fleetRepository.getDevice(
        accessToken: session.accessToken,
        deviceId: deviceId,
      );
      _replaceDevice(_selectedDevice!);
    } on AppException catch (exception) {
      _errorMessage = exception.message;
    } on Exception {
      _errorMessage = 'No se pudo cargar el detalle del dispositivo.';
    } finally {
      _isLoadingDeviceDetail = false;
      notifyListeners();
    }
  }

  Future<FleetVehicle?> createVehicle({
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) async {
    return _saveVehicle(() {
      final session = sessionController.session!;
      return fleetRepository.createVehicle(
        accessToken: session.accessToken,
        plate: plate,
        type: type,
        status: status,
        odometerKm: odometerKm,
      );
    }, prepend: true);
  }

  Future<FleetVehicle?> updateVehicle({
    required String vehicleId,
    required String plate,
    required String type,
    required String status,
    num? odometerKm,
  }) async {
    return _saveVehicle(() {
      final session = sessionController.session!;
      return fleetRepository.updateVehicle(
        accessToken: session.accessToken,
        vehicleId: vehicleId,
        plate: plate,
        type: type,
        status: status,
        odometerKm: odometerKm,
      );
    });
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    final session = sessionController.session;
    if (session == null || _busyVehicleIds.contains(vehicleId)) {
      return false;
    }

    _busyVehicleIds.add(vehicleId);
    _errorMessage = null;
    notifyListeners();

    try {
      await fleetRepository.deleteVehicle(
        accessToken: session.accessToken,
        vehicleId: vehicleId,
      );
      _vehicles =
          _vehicles.where((vehicle) => vehicle.id != vehicleId).toList(growable: false);
      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = null;
      }
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _busyVehicleIds.remove(vehicleId);
      notifyListeners();
    }
  }

  Future<FleetVehicle?> assignDevice({
    required String vehicleId,
    required String imei,
  }) async {
    return _mutateVehicle(vehicleId, () {
      final session = sessionController.session!;
      return fleetRepository.assignDevice(
        accessToken: session.accessToken,
        vehicleId: vehicleId,
        imei: imei,
      );
    });
  }

  Future<FleetVehicle?> unassignDevice({
    required String vehicleId,
    required String imei,
  }) async {
    return _mutateVehicle(vehicleId, () {
      final session = sessionController.session!;
      return fleetRepository.unassignDevice(
        accessToken: session.accessToken,
        vehicleId: vehicleId,
        imei: imei,
      );
    });
  }

  Future<FleetDevice?> createDevice({
    required String imei,
    String? firmware,
    bool online = false,
  }) async {
    return _saveDevice(() {
      final session = sessionController.session!;
      return fleetRepository.createDevice(
        accessToken: session.accessToken,
        imei: imei,
        firmware: firmware,
        online: online,
      );
    }, prepend: true);
  }

  Future<FleetDevice?> updateDevice({
    required String deviceId,
    required String imei,
    String? firmware,
    required bool online,
  }) async {
    return _saveDevice(() {
      final session = sessionController.session!;
      return fleetRepository.updateDevice(
        accessToken: session.accessToken,
        deviceId: deviceId,
        imei: imei,
        firmware: firmware,
        online: online,
      );
    });
  }

  Future<bool> deleteDevice(String deviceId) async {
    final session = sessionController.session;
    if (session == null || _busyDeviceIds.contains(deviceId)) {
      return false;
    }

    _busyDeviceIds.add(deviceId);
    _errorMessage = null;
    notifyListeners();

    try {
      await fleetRepository.deleteDevice(
        accessToken: session.accessToken,
        deviceId: deviceId,
      );
      _devices =
          _devices.where((device) => device.id != deviceId).toList(growable: false);
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = null;
      }
      return true;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return false;
    } finally {
      _busyDeviceIds.remove(deviceId);
      notifyListeners();
    }
  }

  Future<FleetDevice?> toggleDeviceOnline({
    required String deviceId,
    required bool online,
  }) async {
    return _mutateDevice(deviceId, () {
      final session = sessionController.session!;
      return fleetRepository.updateDeviceOnline(
        accessToken: session.accessToken,
        deviceId: deviceId,
        online: online,
      );
    });
  }

  Future<FleetDevice?> updateDeviceFirmware({
    required String deviceId,
    required String firmware,
  }) async {
    return _mutateDevice(deviceId, () {
      final session = sessionController.session!;
      return fleetRepository.updateDeviceFirmware(
        accessToken: session.accessToken,
        deviceId: deviceId,
        firmware: firmware,
      );
    });
  }

  Future<FleetVehicle?> _saveVehicle(
    Future<FleetVehicle> Function() action, {
    bool prepend = false,
  }) async {
    final session = sessionController.session;
    if (session == null || _isSaving) {
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await action();
      _selectedVehicle = updated;
      _replaceVehicle(updated, prepend: prepend);
      return updated;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<FleetDevice?> _saveDevice(
    Future<FleetDevice> Function() action, {
    bool prepend = false,
  }) async {
    final session = sessionController.session;
    if (session == null || _isSaving) {
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await action();
      _selectedDevice = updated;
      _replaceDevice(updated, prepend: prepend);
      return updated;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<FleetVehicle?> _mutateVehicle(
    String vehicleId,
    Future<FleetVehicle> Function() action,
  ) async {
    if (_busyVehicleIds.contains(vehicleId)) {
      return null;
    }

    _busyVehicleIds.add(vehicleId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await action();
      _selectedVehicle = updated;
      _replaceVehicle(updated);
      await loadDevices();
      return updated;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return null;
    } finally {
      _busyVehicleIds.remove(vehicleId);
      notifyListeners();
    }
  }

  Future<FleetDevice?> _mutateDevice(
    String deviceId,
    Future<FleetDevice> Function() action,
  ) async {
    if (_busyDeviceIds.contains(deviceId)) {
      return null;
    }

    _busyDeviceIds.add(deviceId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await action();
      _selectedDevice = updated;
      _replaceDevice(updated);
      return updated;
    } on AppException catch (exception) {
      _errorMessage = exception.message;
      return null;
    } finally {
      _busyDeviceIds.remove(deviceId);
      notifyListeners();
    }
  }

  void _replaceVehicle(FleetVehicle updated, {bool prepend = false}) {
    final index = _vehicles.indexWhere((vehicle) => vehicle.id == updated.id);
    if (index >= 0) {
      _vehicles = List<FleetVehicle>.from(_vehicles)..[index] = updated;
      return;
    }

    _vehicles = prepend
        ? [updated, ..._vehicles]
        : [..._vehicles, updated];
  }

  void _replaceDevice(FleetDevice updated, {bool prepend = false}) {
    final index = _devices.indexWhere((device) => device.id == updated.id);
    if (index >= 0) {
      _devices = List<FleetDevice>.from(_devices)..[index] = updated;
      return;
    }

    _devices = prepend
        ? [updated, ..._devices]
        : [..._devices, updated];
  }
}
