import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/models/shot_status.dart';
import 'package:jingtouben/data/models/video_platform.dart';
import 'package:jingtouben/data/repositories/progress_repository.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/data/repositories/shot_repository.dart';

void main() {
  late AppDatabase db;
  late ShotRepository shots;
  late ProgressRepository progress;
  late String projectId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    shots = ShotRepository(db);
    progress = ProgressRepository(db);
    projectId = await ProjectRepository(db).create('雨夜重逢');
    await shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.full, scene: '雨夜的老街'),
      ShotDraft(index: 1, shotSize: ShotSize.closeUp, scene: '她的眼睛'),
    ]);
  });

  tearDown(() => db.close());

  Future<List<ShotProgress>> current() => progress.watchProject(projectId).first;

  test('没有生成记录时，镜头按顺序列出且都是待生成', () async {
    final board = await current();
    expect(board.map((p) => p.shot.scene), ['雨夜的老街', '她的眼睛']);
    expect(board.map((p) => p.status), everyElement(ShotStatus.pending));
    expect(board.first.generations, isEmpty);
    expect(await shots.hasProgress(projectId), isFalse);
  });

  test('记录、选定、取消选定、删除时同步镜头状态', () async {
    final shotId = (await current()).first.shotId;

    final first = await progress.record(
      shotId: shotId,
      platform: VideoPlatform.jimeng,
      prompt: '全景，雨夜的老街',
      note: '  雨丝太粗  ',
    );
    var shot = (await current()).first;
    expect(shot.status, ShotStatus.generating);
    expect(shot.generations.single.resultNote, '雨丝太粗');
    expect(shot.generations.single.prompt, '全景，雨夜的老街');
    expect(await shots.hasProgress(projectId), isTrue);

    final second = await progress.record(
      shotId: shotId,
      platform: VideoPlatform.kling,
      prompt: '雨夜的老街，全景',
    );
    await progress.togglePick(first);
    shot = (await current()).first;
    expect(shot.status, ShotStatus.picked);
    expect(shot.picked?.id, first);
    expect(shot.generations.map((g) => g.id), [first, second], reason: '按记录先后排序');

    // 改选另一条：同一镜头只保留一条选定
    await progress.togglePick(second);
    shot = (await current()).first;
    expect(shot.generations.where((g) => g.picked).map((g) => g.id), [second]);

    // 再点一次取消选定
    await progress.togglePick(second);
    expect((await current()).first.status, ShotStatus.generating);

    await progress.delete(first);
    await progress.delete(second);
    shot = (await current()).first;
    expect(shot.status, ShotStatus.pending);
    expect(shot.generations, isEmpty);
    expect(await shots.hasProgress(projectId), isFalse);
  });

  test('删除选定的那条后回到生成中', () async {
    final shotId = (await current()).first.shotId;
    final picked = await progress.record(
      shotId: shotId,
      platform: VideoPlatform.jimeng,
      prompt: 'a',
    );
    await progress.record(shotId: shotId, platform: VideoPlatform.jimeng, prompt: 'b');
    await progress.togglePick(picked);

    await progress.delete(picked);

    expect((await current()).first.status, ShotStatus.generating);
  });

  test('修改备注会去掉首尾空白并截断到上限', () async {
    final shotId = (await current()).first.shotId;
    final id = await progress.record(shotId: shotId, platform: VideoPlatform.kling, prompt: 'a');

    await progress.updateNote(id, ' ${'好' * (ProgressRepository.maxNoteLength + 5)} ');

    final note = (await current()).first.generations.single.resultNote;
    expect(note.length, ProgressRepository.maxNoteLength);
  });

  test('记录不存在时选定和删除什么都不做', () async {
    await progress.togglePick('missing');
    await progress.delete('missing');
    expect((await current()).map((p) => p.status), everyElement(ShotStatus.pending));
  });

  test('重新生成替换镜头时，生成记录随旧镜头级联删除', () async {
    final shotId = (await current()).first.shotId;
    await progress.record(shotId: shotId, platform: VideoPlatform.jimeng, prompt: 'a');

    await shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.medium, scene: '新的开场'),
    ]);

    expect(await db.select(db.generations).get(), isEmpty);
    expect(await shots.hasProgress(projectId), isFalse);
  });
}
