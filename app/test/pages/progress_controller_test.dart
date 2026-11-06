import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/models/shot_status.dart';
import 'package:jingtouben/data/models/video_platform.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/progress/controller.dart';

import '../helpers/test_env.dart';

class _UnusedApi implements StoryboardApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestEnv env;
  late String projectId;

  setUp(() async {
    env = TestEnv(api: _UnusedApi());
    projectId = await env.projects.create('雨夜重逢');
    await env.characters.create(projectId, const CharacterProfile(name: '初恋', outfit: '米色风衣'));
    await env.shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.medium, scene: '擦肩相撞', characters: ['初恋']),
      ShotDraft(index: 1, shotSize: ShotSize.closeUp, scene: '她的眼睛'),
    ]);
  });

  tearDown(() => env.db.close());

  ProgressController create() => ProgressController(
    projectId: projectId,
    progress: env.progress,
    characters: env.characters,
    templates: env.templates,
  );

  test('记录时按当前角色卡存下提示词快照，统计和筛选随之更新', () async {
    final controller = create();
    final ready = await controller.stream.firstWhere(
      (s) => !s.loading && s.templates != null && s.characters.isNotEmpty,
    );
    expect(ready.count(ShotStatus.pending), 2);
    expect(ready.pickedRatio, 0);

    final shotId = ready.shots.first.shotId;
    expect(await controller.record(shotId, VideoPlatform.jimeng, note: '人物对了'), isTrue);
    final recorded = await controller.stream.firstWhere(
      (s) => s.shots.first.generations.isNotEmpty,
    );
    final generation = recorded.shots.first.generations.single;
    expect(generation.prompt, '中景，擦肩相撞。人物：初恋，穿米色风衣');
    expect(generation.resultNote, '人物对了');

    await controller.togglePick(generation.id);
    final picked = await controller.stream.firstWhere((s) => s.count(ShotStatus.picked) == 1);
    expect(picked.pickedRatio, 0.5);

    controller.setFilter(ShotStatus.pending);
    expect(controller.state.visible.map((p) => p.shot.scene), ['她的眼睛']);
    controller.setFilter(null);
    expect(controller.state.visible, hasLength(2));

    await controller.updateNote(generation.id, '就用这条');
    await controller.stream.firstWhere(
      (s) => s.shots.first.generations.single.resultNote == '就用这条',
    );
    await controller.delete(generation.id);
    await controller.stream.firstWhere((s) => s.count(ShotStatus.pending) == 2);

    await controller.close();
  });

  test('镜头不存在时不记录', () async {
    final controller = create();
    await controller.stream.firstWhere((s) => !s.loading && s.templates != null);

    expect(await controller.record('missing', VideoPlatform.kling), isFalse);

    await controller.close();
  });
}
