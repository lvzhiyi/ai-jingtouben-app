import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/shot_draft.dart';
import '../models/shot_status.dart';
import '../models/video_platform.dart';
import 'shot_repository.dart';

/// 进度板上的一个镜头：镜头内容、当前状态和它的生成记录（按时间先后）。
class ShotProgress extends Equatable {
  const ShotProgress({
    required this.shotId,
    required this.shot,
    required this.status,
    this.generations = const [],
  });

  final String shotId;
  final ShotDraft shot;
  final ShotStatus status;
  final List<Generation> generations;

  Generation? get picked => generations.where((g) => g.picked).firstOrNull;

  @override
  List<Object?> get props => [shotId, shot, status, generations];
}

/// 镜头进度板的读写：用户拿某个平台的提示词去生成一次，就在这里记一条，并挑出最满意的一次。
///
/// 镜头状态由生成记录推导，在同一个事务里同步写回 `shots.status`：
/// 没有记录是「待生成」，有记录但没选定是「生成中」，选定了一条是「已选定」。
/// 页面只改生成记录，不直接改状态，两者不会对不上。
class ProgressRepository {
  ProgressRepository(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  /// 单条备注的长度上限，和输入框保持一致。
  static const maxNoteLength = 200;

  /// 一次连接查询拿到镜头和生成记录；任一张表变化都会重新推送。
  Stream<List<ShotProgress>> watchProject(String projectId) {
    final shots = _db.shots;
    final generations = _db.generations;
    final query =
        _db.select(shots).join([leftOuterJoin(generations, generations.shotId.equalsExp(shots.id))])
          ..where(shots.projectId.equals(projectId))
          ..orderBy([OrderingTerm.asc(shots.sortOrder), OrderingTerm.asc(generations.createdAt)]);
    return query.watch().map((rows) {
      final byShot = <String, (Shot, List<Generation>)>{};
      for (final row in rows) {
        final shot = row.readTable(shots);
        final entry = byShot.putIfAbsent(shot.id, () => (shot, []));
        final generation = row.readTableOrNull(generations);
        if (generation != null) entry.$2.add(generation);
      }
      return [
        for (final (shot, records) in byShot.values)
          ShotProgress(
            shotId: shot.id,
            shot: shot.toDraft(),
            status: shot.status,
            generations: records,
          ),
      ];
    });
  }

  /// 记一次生成。[prompt] 是当次使用的提示词快照，之后角色卡或模板改了也能回看当时的写法。
  Future<String> record({
    required String shotId,
    required VideoPlatform platform,
    required String prompt,
    String note = '',
  }) async {
    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.generations)
          .insert(
            GenerationsCompanion.insert(
              id: id,
              shotId: shotId,
              platform: platform,
              prompt: prompt,
              resultNote: Value(_clip(note)),
              // 毫秒精度，同一秒内连记两次也能按先后排序
              createdAt: Value(DateTime.now()),
            ),
          );
      await _syncStatus(shotId);
    });
    return id;
  }

  /// 选定这一次作为镜头的最终结果；同一镜头只能选定一条。再点一次已选定的记录则取消选定。
  Future<void> togglePick(String generationId) => _db.transaction(() async {
    final generation = await _find(generationId);
    if (generation == null) return;
    await (_db.update(_db.generations)..where((t) => t.shotId.equals(generation.shotId))).write(
      const GenerationsCompanion(picked: Value(false)),
    );
    if (!generation.picked) {
      await (_db.update(_db.generations)..where((t) => t.id.equals(generationId))).write(
        GenerationsCompanion(picked: const Value(true), updatedAt: Value(DateTime.now())),
      );
    }
    await _syncStatus(generation.shotId);
  });

  Future<void> updateNote(String generationId, String note) =>
      (_db.update(_db.generations)..where((t) => t.id.equals(generationId))).write(
        GenerationsCompanion(resultNote: Value(_clip(note)), updatedAt: Value(DateTime.now())),
      );

  Future<void> delete(String generationId) => _db.transaction(() async {
    final generation = await _find(generationId);
    if (generation == null) return;
    await (_db.delete(_db.generations)..where((t) => t.id.equals(generationId))).go();
    await _syncStatus(generation.shotId);
  });

  Future<Generation?> _find(String id) =>
      (_db.select(_db.generations)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 按生成记录重新推导镜头状态，状态没变时不写，避免多推送一次。
  Future<void> _syncStatus(String shotId) async {
    final records = await (_db.select(
      _db.generations,
    )..where((t) => t.shotId.equals(shotId))).get();
    final status = records.isEmpty
        ? ShotStatus.pending
        : records.any((g) => g.picked)
        ? ShotStatus.picked
        : ShotStatus.generating;
    await (_db.update(_db.shots)
          ..where((t) => t.id.equals(shotId) & t.status.equalsValue(status).not()))
        .write(ShotsCompanion(status: Value(status), updatedAt: Value(DateTime.now())));
  }

  static String _clip(String note) {
    final trimmed = note.trim();
    return trimmed.length <= maxNoteLength ? trimmed : trimmed.substring(0, maxNoteLength);
  }
}
