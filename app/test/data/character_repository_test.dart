import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/repositories/character_repository.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';

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
}
