import '../entities/home_dashboard.dart';

abstract class HomeRepository {
  Future<HomeDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  });
}
