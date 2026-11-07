import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/camera_move.dart';
import '../models/prop_drawing_status.dart';
import '../models/shot_prop.dart';
import '../models/shot_size.dart';
import '../models/shot_status.dart';
import '../models/video_platform.dart';
import 'converters.dart';
import 'schema_versions.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Projects, CharacterCards, Shots, Generations, KeyValues, PropDrawings])
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

  /// 改表时加 1，导出 `drift_schemas/` 快照、重新生成 `schema_versions.dart`，并在 [migration] 里补一步。
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 每一步用对应版本的表定义（schema_versions.dart，由 `drift_dev schema steps` 生成），
    // 不能用当前的 `shots`：旧步骤按当前表结构复制数据，会去读还不存在的新列。
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // v2：镜头的出场角色从 character_ids 改为 character_names。v1 从未写入过这一列，直接重建表。
        await m.alterTable(TableMigration(schema.shots, newColumns: [schema.shots.characterNames]));
      },
      from2To3: (m, schema) async {
        // v3：镜头加运镜和时长。只加列：运镜有默认值，时长可空，旧数据不用回填。
        await m.addColumn(schema.shots, schema.shots.cameraMove);
        await m.addColumn(schema.shots, schema.shots.durationMs);
      },
      from3To4: (m, schema) async {
        // v4：镜头加道具列表（可空，旧镜头按关键词兜底），新增道具绘图缓存表。
        await m.addColumn(schema.shots, schema.shots.propsJson);
        await m.createTable(schema.propDrawings);
      },
    ),
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
