import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/prop_drawing_status.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_prop.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/preview/controller.dart';
import 'package:jingtouben/pages/preview/state.dart';

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
    // 序号 1 是坏行没有落库，列表位置和镜头序号不一致
    await env.shots.replaceAll(projectId, const [
      ShotDraft(index: 0, shotSize: ShotSize.full, scene: '街口', durationMs: 2000),
      ShotDraft(index: 2, shotSize: ShotSize.closeUp, scene: '回头', dialogue: '是你吗'),
      ShotDraft(index: 3, shotSize: ShotSize.long, scene: '远处'),
    ]);
  });

  tearDown(() => env.db.close());

  Future<PreviewController> open({int? startShot, String? project}) async {
    final controller = PreviewController(
      projectId: project ?? projectId,
      shots: env.shots,
      props: env.props,
      generator: env.propGenerator,
      startShot: startShot,
    );
    await controller.load();
    return controller;
  }

  test('加载后从第一镜开始播放，总时长含推导值', () async {
    final controller = await open();
    final state = controller.state;
    expect(state.loading, isFalse);
    expect(state.shots, hasLength(3));
    expect(state.index, 0);
    expect(state.playing, isTrue);
    // 2000 + 有对白 max(2000, 3×250+1000) + 远景无对白 3000
    expect(state.totalMs, 7000);
    await controller.close();
  });

  test('按镜头序号定位起点，找不到时从第一镜开始', () async {
    expect((await open(startShot: 2)).state.index, 1);
    expect((await open(startShot: 9)).state.index, 0);
  });

  test('下一镜到最后停在最后一帧，播放即重播', () async {
    final controller = await open();
    controller
      ..next()
      ..next();
    expect(controller.state.index, 2);
    expect(controller.state.startMs, 4000);

    controller.next();
    expect(controller.state.finished, isTrue);
    expect(controller.state.playing, isFalse);
    controller.next();
    expect(controller.state.index, 2);

    controller.play();
    expect(controller.state.index, 0);
    expect(controller.state.finished, isFalse);
    expect(controller.state.playing, isTrue);
    await controller.close();
  });

  test('上一镜在第一镜时重新开始这一镜，跳转越界忽略，每次跳转都换 cue', () async {
    final controller = await open();
    final cue = controller.state.cue;
    controller.previous();
    expect(controller.state.index, 0);
    expect(controller.state.cue, cue + 1);

    controller
      ..seek(2)
      ..seek(5)
      ..seek(-1);
    expect(controller.state.index, 2);
    controller.previous();
    expect(controller.state.index, 1);
    await controller.close();
  });

  test('暂停 / 继续不换 cue；开关画面描述', () async {
    final controller = await open();
    final cue = controller.state.cue;
    controller.togglePlay();
    expect(controller.state.playing, isFalse);
    controller.togglePlay();
    expect(controller.state.playing, isTrue);
    expect(controller.state.cue, cue);

    expect(controller.state.showScene, isTrue);
    controller.toggleScene();
    expect(controller.state.showScene, isFalse);
    await controller.close();
  });

  test('没有镜头时不播放，操作都无效', () async {
    final empty = await env.projects.create('空项目');
    final controller = await open(project: empty);
    expect(controller.state.shots, isEmpty);
    expect(controller.state.current, isNull);
    controller
      ..play()
      ..next()
      ..previous()
      ..replay();
    expect(controller.state.playing, isFalse);
    expect(controller.state.finished, isFalse);
    await controller.close();
  });

  test('镜头里的生成道具在后台生成，缓存变化时更新状态；内置道具不生成', () async {
    final pid = await env.projects.create('带道具');
    await env.shots.replaceAll(pid, const [
      ShotDraft(
        index: 0,
        shotSize: ShotSize.full,
        scene: '站台',
        characters: ['林夏'],
        shotProps: [
          ShotProp(name: '伞', owner: '林夏'),
          ShotProp(name: '行李箱', owner: '林夏'),
        ],
      ),
      ShotDraft(
        index: 1,
        shotSize: ShotSize.full,
        scene: '街口',
        shotProps: [ShotProp(name: '行李箱')],
      ),
    ]);
    final controller = await open(project: pid);
    // 测试环境的绘图服务不可用：生成失败，记为失败
    await expectLater(
      controller.stream,
      emitsThrough(
        predicate<PreviewState>((s) => s.propRecords['行李箱']?.status == PropDrawingStatus.failed),
      ),
    );
    expect(controller.state.propRecords.keys, ['行李箱']);
    await controller.redraw('行李箱');
    await controller.close();
  });
}
