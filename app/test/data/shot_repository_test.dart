import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/data/repositories/shot_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projects;
  late ShotRepository shots;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    projects = ProjectRepository(db);
    shots = ShotRepository(db);
  });

  tearDown(() => db.close());

  test('replaceAll 覆盖旧镜头，并按顺序读出', () async {
    final projectId = await projects.create('雨夜重逢');
    await shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.full, scene: '旧镜头'),
    ]);
    await shots.replaceAll(projectId, const [
      ShotDraft(index: 1, shotSize: ShotSize.closeUp, scene: '第二镜'),
      ShotDraft(index: 0, shotSize: ShotSize.full, scene: '第一镜'),
    ]);

    final drafts = await shots.loadDrafts(projectId);
    expect(drafts.map((d) => d.scene), ['第一镜', '第二镜']);
  });

  test('删除项目时级联删除镜头', () async {
    final projectId = await projects.create('雨夜重逢');
    await shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.full, scene: '街口'),
    ]);

    await projects.delete(projectId);

    expect(await db.select(db.shots).get(), isEmpty);
  });
  test('出场角色随镜头保存和读出', () async {
    final projectId = await projects.create('雨夜重逢');
    await shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.medium, scene: '擦肩相撞', characters: ['我', '初恋']),
    ]);

    final drafts = await shots.loadDrafts(projectId);
    expect(drafts.single.characters, ['我', '初恋']);
  });
}
