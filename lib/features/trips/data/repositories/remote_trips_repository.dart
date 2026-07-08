import '../../../home/domain/entities/home_dashboard.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/remote_trips_datasource.dart';
import '../models/trip_models.dart';

class RemoteTripsRepository implements TripsRepository {
  const RemoteTripsRepository({
    required this.datasource,
  });

  final RemoteTripsDatasource datasource;

  @override
  Future<List<HomeTrip>> listTrips({
    required String accessToken,
  }) async {
    final models = await datasource.listTrips(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<List<HomeTrip>> searchTrips({
    required String accessToken,
    String? status,
    String? merchantId,
    String? driverId,
    String? vehicleId,
  }) async {
    final models = await datasource.searchTrips(
      accessToken: accessToken,
      status: status,
      merchantId: merchantId,
      driverId: driverId,
      vehicleId: vehicleId,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<HomeTrip> getTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final model = await datasource.getTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
    return model.toDomain();
  }

  @override
  Future<HomeTrip> createTrip({
    required String accessToken,
    required CreateTripRequest request,
  }) async {
    final model = await datasource.createTrip(
      accessToken: accessToken,
      request: request,
    );
    return model.toDomain();
  }

  @override
  Future<HomeTrip> startTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final model = await datasource.startTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
    return model.toDomain();
  }

  @override
  Future<HomeTrip> completeTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final model = await datasource.completeTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
    return model.toDomain();
  }

  @override
  Future<void> deleteTrip({
    required String accessToken,
    required String tripId,
  }) {
    return datasource.deleteTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
  }

  @override
  Future<List<OriginPointModel>> listOriginPoints({
    required String accessToken,
  }) {
    return datasource.listOriginPoints(accessToken: accessToken);
  }

  @override
  Future<OriginPointModel> createOriginPoint({
    required String accessToken,
    required CreateOriginPointRequest request,
  }) {
    return datasource.createOriginPoint(
      accessToken: accessToken,
      request: request,
    );
  }

  @override
  Future<List<HomeDeliveryOrder>> listDeliveryOrdersByTrip({
    required String accessToken,
    required String tripId,
  }) async {
    final models = await datasource.listDeliveryOrdersByTrip(
      accessToken: accessToken,
      tripId: tripId,
    );
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<HomeDeliveryOrder> createDeliveryOrder({
    required String accessToken,
    required CreateDeliveryOrderRequest request,
  }) async {
    final model = await datasource.createDeliveryOrder(
      accessToken: accessToken,
      request: request,
    );
    return model.toDomain();
  }

  @override
  Future<HomeDeliveryOrder> markDelivery({
    required String accessToken,
    required String deliveryOrderId,
  }) async {
    final model = await datasource.markDelivery(
      accessToken: accessToken,
      deliveryOrderId: deliveryOrderId,
    );
    return model.toDomain();
  }

  @override
  Future<List<HomeVehicle>> listVehicles({
    required String accessToken,
  }) async {
    final models = await datasource.listVehicles(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<List<HomeDevice>> listDevices({
    required String accessToken,
  }) async {
    final models = await datasource.listDevices(accessToken: accessToken);
    return models.map((model) => model.toDomain()).toList(growable: false);
  }

  @override
  Future<HomeTrip> rescheduleTrip({
    required String accessToken,
    required String tripId,
    required RescheduleTripRequest request,
  }) async {
    final model = await datasource.rescheduleTrip(
      accessToken: accessToken,
      tripId: tripId,
      request: request,
    );
    return model.toDomain();
  }

  @override
  Future<PublicTripTracking> getPublicTripByTrackingCode({
    required String trackingCode,
  }) {
    return datasource.getPublicTripByTrackingCode(trackingCode: trackingCode);
  }
}
