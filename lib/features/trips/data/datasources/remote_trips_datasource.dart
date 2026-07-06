import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_helpers.dart';
import '../models/trip_models.dart';

class RemoteTripsDatasource {
  RemoteTripsDatasource({
    required this.apiClient,
  });

  final ApiClient apiClient;

  Future<List<HomeTripModel>> listTrips({
    required String accessToken,
  }) async {
    return _parseTrips(
      await _get('/api/v1/trips', accessToken: accessToken),
    );
  }

  Future<List<HomeTripModel>> searchTrips({
    required String accessToken,
    String? status,
    String? merchantId,
    String? driverId,
    String? vehicleId,
  }) async {
    final response = await _get(
      '/api/v1/trips/search',
      accessToken: accessToken,
      queryParameters: queryParamsFrom({
        'status': status,
        'merchantId': merchantId,
        'driverId': driverId,
        'vehicleId': vehicleId,
      }),
    );

    return _parseTrips(response);
  }

  Future<HomeTripModel> getTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final response = await _get(
      '/api/v1/trips/$tripId',
      accessToken: accessToken,
    );

    return HomeTripModel.fromMap(expectMap(response, 'trip'));
  }

  Future<HomeTripModel> createTrip({
    required String accessToken,
    required CreateTripRequest request,
  }) async {
    final response = await _post(
      '/api/v1/trips',
      accessToken: accessToken,
      body: request.toJson(),
      expectedStatusCodes: const {200, 201},
    );

    return HomeTripModel.fromMap(expectMap(response, 'trip'));
  }

  Future<HomeTripModel> startTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final response = await _post(
      '/api/v1/trips/$tripId/start',
      accessToken: accessToken,
    );

    return HomeTripModel.fromMap(expectMap(response, 'trip'));
  }

  Future<HomeTripModel> completeTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final response = await _post(
      '/api/v1/trips/$tripId/complete',
      accessToken: accessToken,
    );

    return HomeTripModel.fromMap(expectMap(response, 'trip'));
  }

  Future<void> deleteTrip({
    required String accessToken,
    required String tripId,
  }) async {
    await _delete(
      '/api/v1/trips/$tripId',
      accessToken: accessToken,
      expectedStatusCodes: const {200, 204},
    );
  }

  Future<List<OriginPointModel>> listOriginPoints({
    required String accessToken,
  }) async {
    final response = await _get(
      '/api/v1/origin-points',
      accessToken: accessToken,
    );

    return expectList(response, 'origin points')
        .whereType<Map<String, dynamic>>()
        .map(OriginPointModel.fromMap)
        .toList(growable: false);
  }

  Future<OriginPointModel> createOriginPoint({
    required String accessToken,
    required CreateOriginPointRequest request,
  }) async {
    final response = await _post(
      '/api/v1/origin-points',
      accessToken: accessToken,
      body: request.toJson(),
      expectedStatusCodes: const {200, 201},
    );

    return OriginPointModel.fromMap(expectMap(response, 'origin point'));
  }

  Future<List<HomeDeliveryOrderModel>> listDeliveryOrdersByTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final response = await _get(
      '/api/v1/delivery-orders/trip/$tripId',
      accessToken: accessToken,
    );

    return expectList(response, 'delivery orders')
        .whereType<Map<String, dynamic>>()
        .map(HomeDeliveryOrderModel.fromMap)
        .toList(growable: false);
  }

  Future<HomeDeliveryOrderModel> createDeliveryOrder({
    required String accessToken,
    required CreateDeliveryOrderRequest request,
  }) async {
    final response = await _post(
      '/api/v1/delivery-orders',
      accessToken: accessToken,
      body: request.toJson(),
      expectedStatusCodes: const {200, 201},
    );

    return HomeDeliveryOrderModel.fromMap(
      expectMap(response, 'delivery order'),
    );
  }

  Future<HomeDeliveryOrderModel> markDelivery({
    required String accessToken,
    required String deliveryOrderId,
  }) async {
    final response = await _post(
      '/api/v1/delivery-orders/$deliveryOrderId/delivery',
      accessToken: accessToken,
    );

    return HomeDeliveryOrderModel.fromMap(
      expectMap(response, 'delivery order'),
    );
  }

  Future<List<HomeVehicleModel>> listVehicles({
    required String accessToken,
  }) async {
    final response = await _get(
      '/api/v1/fleet/vehicles',
      accessToken: accessToken,
    );

    return expectList(response, 'vehicles')
        .whereType<Map<String, dynamic>>()
        .map(HomeVehicleModel.fromMap)
        .toList(growable: false);
  }

  Future<List<HomeDeviceModel>> listDevices({
    required String accessToken,
  }) async {
    final response = await _get(
      '/api/v1/fleet/devices',
      accessToken: accessToken,
    );

    return expectList(response, 'devices')
        .whereType<Map<String, dynamic>>()
        .map(HomeDeviceModel.fromMap)
        .toList(growable: false);
  }

  List<HomeTripModel> _parseTrips(Object? response) {
    return expectList(response, 'trips')
        .whereType<Map<String, dynamic>>()
        .map(HomeTripModel.fromMap)
        .toList(growable: false);
  }

  Future<Object?> _get(
    String path, {
    required String accessToken,
    Map<String, String>? queryParameters,
  }) async {
    try {
      return await apiClient.get(
        path,
        headers: authHeaders(accessToken),
        queryParameters: queryParameters,
        expectedStatusCodes: const {200},
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<Object?> _post(
    String path, {
    required String accessToken,
    Object? body,
    Set<int> expectedStatusCodes = const {200},
  }) async {
    try {
      return await apiClient.post(
        path,
        headers: authHeaders(accessToken),
        body: body,
        expectedStatusCodes: expectedStatusCodes,
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }

  Future<void> _delete(
    String path, {
    required String accessToken,
    Set<int> expectedStatusCodes = const {200},
  }) async {
    try {
      await apiClient.delete(
        path,
        headers: authHeaders(accessToken),
        expectedStatusCodes: expectedStatusCodes,
      );
    } on ApiException catch (exception) {
      throw AppException(exception.message);
    }
  }
}
