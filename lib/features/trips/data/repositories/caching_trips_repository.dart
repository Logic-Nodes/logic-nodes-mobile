import '../../../../core/storage/offline_cache_runner.dart';
import '../../../../core/storage/offline_cache_store.dart';
import '../../../home/data/models/home_dashboard_codec.dart';
import '../../../home/domain/entities/home_dashboard.dart';
import '../../data/models/trip_models.dart';
import '../../domain/repositories/trips_repository.dart';
import 'remote_trips_repository.dart';

class CachingTripsRepository implements TripsRepository {
  CachingTripsRepository({
    required RemoteTripsRepository remote,
    required OfflineCacheRunner cacheRunner,
    required this.userIdResolver,
  })  : _remote = remote,
        _cacheRunner = cacheRunner;

  final RemoteTripsRepository _remote;
  final OfflineCacheRunner _cacheRunner;
  final String? Function() userIdResolver;

  bool lastListUsedCache = false;

  String? get _userId => userIdResolver();

  @override
  Future<List<HomeTrip>> listTrips({
    required String accessToken,
  }) async {
    lastListUsedCache = false;
    final userId = _userId;
    if (userId == null) {
      return _remote.listTrips(accessToken: accessToken);
    }

    return _cacheRunner.run(
      cacheKey: OfflineCacheKeys.trips(userId),
      remote: () => _remote.listTrips(accessToken: accessToken),
      encode: HomeDashboardCodec.encodeTrips,
      decode: HomeDashboardCodec.decodeTrips,
    );
  }

  @override
  Future<List<HomeTrip>> searchTrips({
    required String accessToken,
    String? status,
    String? merchantId,
    String? driverId,
    String? vehicleId,
  }) {
    return _remote.searchTrips(
      accessToken: accessToken,
      status: status,
      merchantId: merchantId,
      driverId: driverId,
      vehicleId: vehicleId,
    );
  }

  @override
  Future<HomeTrip> getTrip({
    required String accessToken,
    required String tripId,
  }) {
    return _remote.getTrip(accessToken: accessToken, tripId: tripId);
  }

  @override
  Future<HomeTrip> createTrip({
    required String accessToken,
    required CreateTripRequest request,
  }) {
    return _remote.createTrip(accessToken: accessToken, request: request);
  }

  @override
  Future<HomeTrip> startTrip({
    required String accessToken,
    required String tripId,
  }) {
    return _remote.startTrip(accessToken: accessToken, tripId: tripId);
  }

  @override
  Future<HomeTrip> completeTrip({
    required String accessToken,
    required String tripId,
  }) {
    return _remote.completeTrip(accessToken: accessToken, tripId: tripId);
  }

  @override
  Future<void> deleteTrip({
    required String accessToken,
    required String tripId,
  }) {
    return _remote.deleteTrip(accessToken: accessToken, tripId: tripId);
  }

  @override
  Future<List<OriginPointModel>> listOriginPoints({
    required String accessToken,
  }) {
    return _remote.listOriginPoints(accessToken: accessToken);
  }

  @override
  Future<OriginPointModel> createOriginPoint({
    required String accessToken,
    required CreateOriginPointRequest request,
  }) {
    return _remote.createOriginPoint(
      accessToken: accessToken,
      request: request,
    );
  }

  @override
  Future<List<HomeDeliveryOrder>> listDeliveryOrdersByTrip({
    required String accessToken,
    required String tripId,
  }) {
    return _remote.listDeliveryOrdersByTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
  }

  @override
  Future<HomeDeliveryOrder> createDeliveryOrder({
    required String accessToken,
    required CreateDeliveryOrderRequest request,
  }) {
    return _remote.createDeliveryOrder(
      accessToken: accessToken,
      request: request,
    );
  }

  @override
  Future<HomeDeliveryOrder> markDelivery({
    required String accessToken,
    required String deliveryOrderId,
  }) {
    return _remote.markDelivery(
      accessToken: accessToken,
      deliveryOrderId: deliveryOrderId,
    );
  }

  @override
  Future<List<HomeVehicle>> listVehicles({
    required String accessToken,
  }) {
    return _remote.listVehicles(accessToken: accessToken);
  }

  @override
  Future<List<HomeDevice>> listDevices({
    required String accessToken,
  }) {
    return _remote.listDevices(accessToken: accessToken);
  }

  @override
  Future<HomeTrip> rescheduleTrip({
    required String accessToken,
    required String tripId,
    required RescheduleTripRequest request,
  }) {
    return _remote.rescheduleTrip(
      accessToken: accessToken,
      tripId: tripId,
      request: request,
    );
  }

  @override
  Future<PublicTripTracking> getPublicTripByTrackingCode({
    required String trackingCode,
  }) {
    return _remote.getPublicTripByTrackingCode(trackingCode: trackingCode);
  }
}
