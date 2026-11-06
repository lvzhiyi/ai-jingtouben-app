import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/shot_draft.dart';
import '../models/shot_status.dart';

class ShotRepository {
  ShotRepository(this._db, {this._uuid = const Uuid()});

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
            characterNames: Value(draft.characters),
            cameraMove: Value(draft.cameraMove),
            durationMs: Value(draft.durationMs),
          ),
      ]);
    });
  });

  /// 是否已经在进度板上记过生成。重新生成会替换全部镜头并级联删除生成记录，页面据此先确认。
  Future<bool> hasProgress(String projectId) async {
    final query = _db.selectOnly(_db.shots)
      ..addColumns([_db.shots.id])
      ..where(
        _db.shots.projectId.equals(projectId) &
            _db.shots.status.equalsValue(ShotStatus.pending).not(),
      )
      ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  SimpleSelectStatement<$ShotsTable, Shot> _byProject(String projectId) => _db.select(_db.shots)
    ..where((t) => t.projectId.equals(projectId))
    ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
}

/// 存储层的镜头转成页面使用的镜头内容。
extension ShotToDraft on Shot {
  ShotDraft toDraft() => ShotDraft(
    index: sortOrder,
    shotSize: shotSize,
    scene: scene,
    dialogue: dialogue,
    reason: reason,
    characters: characterNames,
    cameraMove: cameraMove,
    durationMs: durationMs,
  );
}
