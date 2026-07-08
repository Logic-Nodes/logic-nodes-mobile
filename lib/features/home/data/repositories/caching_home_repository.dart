import '../../../../core/storage/offline_cache_store.dart';
import '../../../../core/storage/offline_cache_runner.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home_dashboard_codec.dart';
import 'remote_home_repository.dart';

class CachingHomeRepository implements HomeRepository {
  CachingHomeRepository({
    required RemoteHomeRepository remote,
    required OfflineCacheRunner cacheRunner,
  })  : _remote = remote,
        _cacheRunner = cacheRunner;

  final RemoteHomeRepository _remote;
  final OfflineCacheRunner _cacheRunner;

  @override
  Future<HomeDashboard> loadDashboard({
    required String accessToken,
    required String userId,
    required String email,
    required bool isFleetManager,
  }) {
    return _cacheRunner.run(
      cacheKey: OfflineCacheKeys.dashboard(userId),
      remote: () => _remote.loadDashboard(
        accessToken: accessToken,
        userId: userId,
        email: email,
        isFleetManager: isFleetManager,
      ),
      encode: HomeDashboardCodec.encode,
      decode: HomeDashboardCodec.decode,
      markOffline: (cached) => cached.copyWith(
        isFromCache: true,
        scopeNotice:
            'Mostrando datos guardados en SQLite. Se sincronizaran al recuperar conexion.',
      ),
    );
  }
}
