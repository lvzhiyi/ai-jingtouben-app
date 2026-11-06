import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/camera_move.dart';

import '../generated_migrations/schema.dart';

/// 每次改表：`dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/drift_schema_vN.json`，
/// 再 `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/` 和
/// `dart run drift_dev schema steps drift_schemas/ lib/data/db/schema_versions.dart`，然后在这里补一个版本的用例。
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 → v2：表结构与 v2 快照一致，已有镜头保留', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute("INSERT INTO projects (id, title, story) VALUES ('p1', '雨夜重逢', '雨夜')")
      ..execute(
        'INSERT INTO shots (id, project_id, sort_order, shot_size, scene) '
        "VALUES ('s1', 'p1', 0, 'full', '雨夜老街')",
      );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    // 库停在 v2，没有 v3 的列，不能用当前的 Shot 读，直接查原始行。
    final shot = await db.customSelect('SELECT scene, character_names FROM shots').getSingle();
    expect(shot.read<String>('scene'), '雨夜老街');
    expect(shot.read<String>('character_names'), '[]');
    await db.close();
  });

  test('v2 → v3：表结构与 v3 快照一致，旧镜头运镜为固定、时长为空', () async {
    final schema = await verifier.schemaAt(2);
    schema.rawDatabase
      ..execute("INSERT INTO projects (id, title, story) VALUES ('p1', '雨夜重逢', '雨夜')")
      ..execute(
        'INSERT INTO shots (id, project_id, sort_order, shot_size, scene, character_names) '
        "VALUES ('s1', 'p1', 0, 'closeUp', '林夏回头', '[\"林夏\"]')",
      );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final shot = await db.select(db.shots).getSingle();
    expect(shot.scene, '林夏回头');
    expect(shot.characterNames, ['林夏']);
    expect(shot.cameraMove, CameraMove.fixed);
    expect(shot.durationMs, isNull);
    await db.close();
  });

  test('v1 → v3：连续升级不丢镜头', () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase
      ..execute("INSERT INTO projects (id, title, story) VALUES ('p1', '雨夜重逢', '雨夜')")
      ..execute(
        'INSERT INTO shots (id, project_id, sort_order, shot_size, scene) '
        "VALUES ('s1', 'p1', 0, 'full', '雨夜老街')",
      );

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);

    final shot = await db.select(db.shots).getSingle();
    expect(shot.scene, '雨夜老街');
    expect(shot.cameraMove, CameraMove.fixed);
    await db.close();
  });
}
