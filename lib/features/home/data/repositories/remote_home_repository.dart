import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/remote_home_datasource.dart';

class RemoteHomeRepository implements HomeRepository {
  const RemoteHomeRepository({
    required this.datasource,
  });

  final RemoteHomeDatasource datasource;

  @override
  Future<HomeDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) async {
    final dashboard = await datasource.loadDashboard(
      accessToken: accessToken,
      userId: userId,
      email: email,
      isFleetManager: isFleetManager,
    );

    return dashboard.toDomain();
  }
}
