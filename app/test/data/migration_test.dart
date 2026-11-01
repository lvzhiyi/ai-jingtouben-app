import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';

import '../generated_migrations/schema.dart';

/// 每次改表：`dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/drift_schema_vN.json`，
/// 再 `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/`，然后在这里补一个版本的用例。
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

    final shot = await db.select(db.shots).getSingle();
    expect(shot.scene, '雨夜老街');
    expect(shot.characterNames, isEmpty);
    await db.close();
  });
}
