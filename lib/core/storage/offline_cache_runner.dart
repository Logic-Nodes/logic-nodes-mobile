import '../errors/app_exception.dart';
import 'offline_cache_store.dart';

class OfflineCacheRunner {
  const OfflineCacheRunner({
    required this.store,
  });

  final OfflineCacheStore store;

  Future<T> run<T>({
    required String cacheKey,
    required Future<T> Function() remote,
    required String Function(T value) encode,
    required T Function(String payload) decode,
    T Function(T cached)? markOffline,
  }) async {
    try {
      final value = await remote();
      await store.put(cacheKey, encode(value));
      return value;
    } on AppException {
      final payload = await store.get(cacheKey);
      if (payload == null || payload.isEmpty) {
        rethrow;
      }

      final cached = decode(payload);
      return markOffline?.call(cached) ?? cached;
    }
  }
}
