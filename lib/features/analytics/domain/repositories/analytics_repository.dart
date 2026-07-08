import '../../domain/entities/analytics_trip.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  });

  Future<TripAnalyticsDetail> getTripDetail({
    required String accessToken,
    required String tripId,
  });
}
