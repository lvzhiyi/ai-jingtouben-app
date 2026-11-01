import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/shot_size.dart';
import '../models/shot_status.dart';
import '../models/video_platform.dart';
import 'converters.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Projects, CharacterCards, Shots, Generations, KeyValues])
class AppDatabase extends _$AppDatabase {
  /// 测试里传入 `NativeDatabase.memory()`。
  AppDatabase(super.executor);

  /// 移动端使用应用支持目录下的 SQLite 文件；Web 端使用 wasm 版 SQLite（需要 web/ 下的两个文件）。
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'jingtouben',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  /// 改表时加 1，并在 [migration] 里写升级步骤。
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2：镜头的出场角色从 character_ids 改为 character_names。v1 从未写入过这一列，直接重建表。
        await m.alterTable(TableMigration(shots, newColumns: [shots.characterNames]));
      }
    },
    beforeOpen: (details) async {
      // SQLite 默认不检查外键，必须每次连接都打开，删除项目时才会级联删除镜头。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<String?> readValue(String key) async {
    final row = await (select(keyValues)..where((t) => t.entryKey.equals(key))).getSingleOrNull();
    return row?.entryValue;
  }

  Future<void> writeValue(String key, String value) =>
      into(keyValues)
          .insertOnConflictUpdate(KeyValuesCompanion.insert(entryKey: key, entryValue: value));
}
