import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/repositories/character_repository.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/pages/characters/controller.dart';

void main() {
  late AppDatabase db;
  late CharacterRepository characters;
  late String projectId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    characters = CharacterRepository(db);
    projectId = await ProjectRepository(db).create('雨夜重逢');
  });

  tearDown(() => db.close());

  test('保存后列表自动更新；重名判断排除正在编辑的角色', () async {
    final controller = CharactersController(projectId: projectId, repository: characters);
    await controller.stream.firstWhere((s) => !s.loading);

    await controller.save(const CharacterProfile(name: '初恋'));
    final state = await controller.stream.firstWhere((s) => s.characters.isNotEmpty);
    final id = state.characters.single.id;

    expect(controller.isNameTaken(' 初恋 '), isTrue);
    expect(controller.isNameTaken('初恋', exceptId: id), isFalse);

    await controller.save(
      const CharacterProfile(name: '初恋', outfit: '米色风衣'),
      id: id,
    );
    final updated = await controller.stream.firstWhere(
      (s) => s.characters.single.outfit.isNotEmpty,
    );
    expect(updated.characters.single.id, id);

    await controller.close();
  });
}
