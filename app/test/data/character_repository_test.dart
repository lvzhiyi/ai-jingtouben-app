import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_prop.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/repositories/character_repository.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/data/repositories/shot_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projects;
  late CharacterRepository characters;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    projects = ProjectRepository(db);
    characters = CharacterRepository(db);
  });

  tearDown(() => db.close());

  test('新建、修改后按名称读出角色资料，只读本项目的', () async {
    final projectId = await projects.create('雨夜重逢');
    final otherId = await projects.create('另一部');
    final id = await characters.create(projectId, const CharacterProfile(name: '我'));
    await characters.create(projectId, const CharacterProfile(name: '初恋', appearance: '齐肩短发'));
    await characters.create(otherId, const CharacterProfile(name: '路人'));

    await characters.update(id, const CharacterProfile(name: '我', outfit: '黑色雨衣'));

    expect(await characters.loadProfiles(projectId), const [
      CharacterProfile(name: '初恋', appearance: '齐肩短发'),
      CharacterProfile(name: '我', outfit: '黑色雨衣'),
    ]);
  });

  test('删除项目时级联删除角色卡', () async {
    final projectId = await projects.create('雨夜重逢');
    await characters.create(projectId, const CharacterProfile(name: '我'));

    await projects.delete(projectId);

    expect(await characters.loadProfiles(projectId), isEmpty);
  });
  test('角色改名时同步镜头里的出场角色名', () async {
    final projectId = await projects.create('雨夜重逢');
    final shots = ShotRepository(db);
    final id = await characters.create(projectId, const CharacterProfile(name: '初恋'));
    await shots.replaceAll(projectId, const [
      ShotDraft(
        index: 0,
        shotSize: ShotSize.medium,
        scene: '擦肩相撞',
        characters: ['我', '初恋'],
        shotProps: [
          ShotProp(name: '伞', owner: '初恋'),
          ShotProp(name: '书', owner: '我'),
        ],
      ),
      ShotDraft(index: 1, shotSize: ShotSize.full, scene: '旧镜头', characters: ['初恋']),
    ]);

    await characters.update(id, const CharacterProfile(name: '白月光'));

    final drafts = await shots.loadDrafts(projectId);
    expect(drafts.first.characters, ['我', '白月光']);
    expect(drafts.first.shotProps, const [
      ShotProp(name: '伞', owner: '白月光'),
      ShotProp(name: '书', owner: '我'),
    ]);
    expect(drafts.last.shotProps, isNull, reason: '旧镜头没有道具，改名后仍为空');
  });
}
