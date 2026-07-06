import '../../../home/domain/entities/home_dashboard.dart';
import '../../data/models/trip_models.dart';

abstract class TripsRepository {
  Future<List<HomeTrip>> listTrips({
    required String accessToken,
  });

  Future<List<HomeTrip>> searchTrips({
    required String accessToken,
    String? status,
    String? merchantId,
    String? driverId,
    String? vehicleId,
  });

  Future<HomeTrip> getTrip({
    required String accessToken,
    required String tripId,
  });

  Future<HomeTrip> createTrip({
    required String accessToken,
    required CreateTripRequest request,
  });

  Future<HomeTrip> startTrip({
    required String accessToken,
    required String tripId,
  });

  Future<HomeTrip> completeTrip({
    required String accessToken,
    required String tripId,
  });

  Future<void> deleteTrip({
    required String accessToken,
    required String tripId,
  });

  Future<List<OriginPointModel>> listOriginPoints({
    required String accessToken,
  });

  Future<OriginPointModel> createOriginPoint({
    required String accessToken,
    required CreateOriginPointRequest request,
  });

  Future<List<HomeDeliveryOrder>> listDeliveryOrdersByTrip({
    required String accessToken,
    required String tripId,
  });

  Future<HomeDeliveryOrder> createDeliveryOrder({
    required String accessToken,
    required CreateDeliveryOrderRequest request,
  });

  Future<HomeDeliveryOrder> markDelivery({
    required String accessToken,
    required String deliveryOrderId,
  });

  Future<List<HomeVehicle>> listVehicles({
    required String accessToken,
  });

  Future<List<HomeDevice>> listDevices({
    required String accessToken,
  });
}
