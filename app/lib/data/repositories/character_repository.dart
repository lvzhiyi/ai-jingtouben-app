import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/character_profile.dart';

class CharacterRepository {
  CharacterRepository(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  /// 与服务端校验保持一致：一次生成最多带 10 个角色。
  static const maxPerProject = 10;

  /// 按名称排序；编辑后顺序不跳动。
  Stream<List<CharacterCard>> watchByProject(String projectId) => _byProject(projectId).watch();

  /// 生成分镜和拼接提示词时使用的角色资料。
  Future<List<CharacterProfile>> loadProfiles(String projectId) async => [
    for (final card in await _byProject(projectId).get()) card.toProfile(),
  ];

  Future<String> create(String projectId, CharacterProfile profile) async {
    final id = _uuid.v4();
    await _db
        .into(_db.characterCards)
        .insert(
          CharacterCardsCompanion.insert(
            id: id,
            projectId: projectId,
            name: profile.name,
            appearance: Value(profile.appearance),
            outfit: Value(profile.outfit),
          ),
        );
    return id;
  }

  Future<void> update(String id, CharacterProfile profile) =>
      (_db.update(_db.characterCards)..where((t) => t.id.equals(id))).write(
        CharacterCardsCompanion(
          name: Value(profile.name),
          appearance: Value(profile.appearance),
          outfit: Value(profile.outfit),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> delete(String id) =>
      (_db.delete(_db.characterCards)..where((t) => t.id.equals(id))).go();

  SimpleSelectStatement<$CharacterCardsTable, CharacterCard> _byProject(String projectId) =>
      _db.select(_db.characterCards)
        ..where((t) => t.projectId.equals(projectId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]);
}

extension CharacterCardProfile on CharacterCard {
  CharacterProfile toProfile() =>
      CharacterProfile(name: name, appearance: appearance, outfit: outfit);
}
