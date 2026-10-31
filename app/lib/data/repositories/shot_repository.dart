import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/shot_draft.dart';
import '../models/shot_status.dart';

class ShotRepository {
  ShotRepository(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<Shot>> watchByProject(String projectId) => _byProject(projectId).watch();

  Future<List<ShotDraft>> loadDrafts(String projectId) async => [
    for (final shot in await _byProject(projectId).get()) shot.toDraft(),
  ];

  /// 用一次完整生成的结果替换项目下的全部镜头。在事务里执行，中途失败不会留下一半新一半旧。
  Future<void> replaceAll(String projectId, List<ShotDraft> drafts) => _db.transaction(() async {
    await (_db.delete(_db.shots)..where((t) => t.projectId.equals(projectId))).go();
    await _db.batch((batch) {
      batch.insertAll(_db.shots, [
        for (final draft in drafts)
          ShotsCompanion.insert(
            id: _uuid.v4(),
            projectId: projectId,
            sortOrder: draft.index,
            shotSize: draft.shotSize,
            scene: draft.scene,
            dialogue: Value(draft.dialogue),
            reason: Value(draft.reason),
          ),
      ]);
    });
  });

  Future<void> updateStatus(String shotId, ShotStatus status) =>
      (_db.update(_db.shots)..where((t) => t.id.equals(shotId))).write(
        ShotsCompanion(status: Value(status), updatedAt: Value(DateTime.now())),
      );

  SimpleSelectStatement<$ShotsTable, Shot> _byProject(String projectId) =>
      _db.select(_db.shots)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
}

extension on Shot {
  ShotDraft toDraft() => ShotDraft(
    index: sortOrder,
    shotSize: shotSize,
    scene: scene,
    dialogue: dialogue,
    reason: reason,
  );
}
