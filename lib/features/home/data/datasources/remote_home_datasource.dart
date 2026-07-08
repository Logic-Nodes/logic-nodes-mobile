import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/home_dashboard_model.dart';

class RemoteHomeDatasource {
  RemoteHomeDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<HomeDashboardModel> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) async {
    final headers = _authHeaders(accessToken);

    try {
      final futures = await Future.wait<Object?>([
        apiClient.get(
          '/api/v1/trips',
          headers: headers,
          expectedStatusCodes: const {200},
        ),
        apiClient.get(
          '/api/v1/alerts',
          headers: headers,
          expectedStatusCodes: const {200},
        ),
        apiClient.get(
          '/api/v1/fleet/vehicles',
          headers: headers,
          expectedStatusCodes: const {200},
        ),
        apiClient.get(
          '/api/v1/fleet/devices',
          headers: headers,
          expectedStatusCodes: const {200},
        ),
        apiClient.get(
          '/api/v1/monitoring/sessions/active',
          headers: headers,
          expectedStatusCodes: const {200},
        ),
        isFleetManager
            ? apiClient.get(
                '/api/v1/employees',
                headers: headers,
                expectedStatusCodes: const {200},
              )
            : Future<Object?>.value(const []),
      ]);

      final allTrips = _parseTrips(futures[0]);
      final allAlerts = _parseAlerts(futures[1]);
      final allVehicles = _parseVehicles(futures[2]);
      final allDevices = _parseDevices(futures[3]);
      final allSessions = _parseSessions(futures[4]);
      final employeeRows = _expectList(futures[5], 'employees');

      final merchantId = isFleetManager
          ? _resolveMerchantId(
              employees: employeeRows,
              userId: userId,
            )
          : null;
      final relevantTrips = _filterTrips(
        trips: allTrips,
        email: email,
        isFleetManager: isFleetManager,
        merchantId: merchantId,
      );
      final relevantTripIds = relevantTrips.map((trip) => trip.id).toSet();
      final relevantDeliveryOrderIds = relevantTrips
          .expand((trip) => trip.deliveryOrders)
          .map((order) => order.id)
          .toSet();
      final relevantVehicleIds = relevantTrips
          .map((trip) => trip.vehicleId)
          .whereType<String>()
          .toSet();

      final relevantAlerts = allAlerts
          .where(
            (alert) =>
                alert.deliveryOrderId != null &&
                relevantDeliveryOrderIds.contains(alert.deliveryOrderId),
          )
          .toList(growable: false);
      final relevantVehicles = isFleetManager
          ? allVehicles
          : allVehicles
              .where((vehicle) => relevantVehicleIds.contains(vehicle.id))
              .toList(growable: false);
      final relevantVehiclePlates =
          relevantVehicles.map((vehicle) => vehicle.plate).toSet();
      final relevantDevices = isFleetManager
          ? allDevices
          : allDevices
              .where(
                (device) =>
                    device.vehiclePlate != null &&
                    relevantVehiclePlates.contains(device.vehiclePlate),
              )
              .toList(growable: false);
      final relevantSessions = isFleetManager
          ? allSessions
              .where((session) => relevantTripIds.contains(session.tripId))
              .toList(growable: false)
          : allSessions
              .where((session) => relevantTripIds.contains(session.tripId))
              .toList(growable: false);

      final scopeApplied = !isFleetManager || merchantId != null;
      final scopeNotice = isFleetManager && merchantId == null
          ? 'No se encontró una relación con un comercio para el usuario autenticado. Se muestra el inventario global de la flota y todos los viajes visibles.'
          : null;

      return HomeDashboardModel(
        trips: relevantTrips,
        alerts: relevantAlerts,
        vehicles: relevantVehicles,
        devices: relevantDevices,
        activeSessions: relevantSessions,
        loadedAt: DateTime.now(),
        scopeApplied: scopeApplied,
        scopeNotice: scopeNotice,
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    } on AppException {
      rethrow;
    } on Exception catch (exception) {
      throw AppException('No se pudieron cargar los datos del inicio. $exception');
    }
  }

  List<HomeTripModel> _filterTrips({
    required List<HomeTripModel> trips,
    required String email,
    required bool isFleetManager,
    required String? merchantId,
  }) {
    if (isFleetManager && merchantId != null) {
      return trips
          .where((trip) => trip.merchantId == merchantId)
          .toList(growable: false);
    }

    if (!isFleetManager) {
      final normalizedEmail = email.trim().toLowerCase();
      return trips
          .where(
            (trip) => trip.deliveryOrders.any(
              (order) =>
                  order.clientEmail.trim().toLowerCase() == normalizedEmail,
            ),
          )
          .toList(growable: false);
    }

    return trips;
  }

  String? _resolveMerchantId({
    required List<Object?> employees,
    required String userId,
  }) {
    for (final row in employees) {
      if (row is! Map<String, dynamic>) {
        continue;
      }

      if ('${row['userId']}' == userId) {
        final merchantId = '${row['merchantId']}'.trim();
        if (merchantId.isNotEmpty && merchantId != 'null') {
          return merchantId;
        }
      }
    }

    return null;
  }

  List<HomeTripModel> _parseTrips(Object? response) {
    final rows = _expectList(response, 'trips');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(HomeTripModel.fromMap)
        .toList(growable: false);
  }

  List<HomeAlertModel> _parseAlerts(Object? response) {
    final rows = _expectList(response, 'alerts');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(HomeAlertModel.fromMap)
        .toList(growable: false);
  }

  List<HomeVehicleModel> _parseVehicles(Object? response) {
    final rows = _expectList(response, 'vehicles');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(HomeVehicleModel.fromMap)
        .toList(growable: false);
  }

  List<HomeDeviceModel> _parseDevices(Object? response) {
    final rows = _expectList(response, 'devices');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(HomeDeviceModel.fromMap)
        .toList(growable: false);
  }

  List<HomeMonitoringSessionModel> _parseSessions(Object? response) {
    final rows = _expectList(response, 'monitoring sessions');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(HomeMonitoringSessionModel.fromMap)
        .toList(growable: false);
  }

  List<Object?> _expectList(Object? value, String source) {
    if (value is List) {
      return value.cast<Object?>();
    }

    throw AppException('Respuesta inesperada del servidor.');
  }

  Map<String, String> _authHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
    };
  }
}
