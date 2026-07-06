import 'package:sqflite/sqflite.dart';

import 'local_database.dart';

class OfflineCacheStore {
  OfflineCacheStore({
    LocalDatabase? database,
  }) : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  Future<void> put(String key, String payload) async {
    final db = await _database.database;
    await db.insert(
      'cache_entries',
      {
        'cache_key': key,
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> get(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      'cache_entries',
      columns: const ['payload'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['payload'] as String?;
  }

  Future<DateTime?> updatedAt(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      'cache_entries',
      columns: const ['updated_at'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final raw = rows.first['updated_at'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> delete(String key) async {
    final db = await _database.database;
    await db.delete(
      'cache_entries',
      where: 'cache_key = ?',
      whereArgs: [key],
    );
  }

  Future<void> clearAll() async {
    final db = await _database.database;
    await db.delete('cache_entries');
  }

  Future<void> clearUser(String userId) async {
    final db = await _database.database;
    await db.delete(
      'cache_entries',
      where: 'cache_key LIKE ?',
      whereArgs: ['%:$userId'],
    );
  }
}

abstract final class OfflineCacheKeys {
  static String dashboard(String userId) => 'dashboard:$userId';
  static String alerts(String userId) => 'alerts:$userId';
  static String vehicles(String userId) => 'vehicles:$userId';
  static String devices(String userId) => 'devices:$userId';
  static String trips(String userId) => 'trips:$userId';
}
