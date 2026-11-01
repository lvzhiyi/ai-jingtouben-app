import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/data/repositories/shot_repository.dart';
import 'package:jingtouben/data/storyboard/shot_line_parser.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/storyboard/controller.dart';
import 'package:jingtouben/pages/storyboard/state.dart';

class _FakeApi implements StoryboardApi {
  _FakeApi(this._source);

  final Stream<GenerationUpdate> Function() _source;

  @override
  Stream<GenerationUpdate> generate({
    required String story,
    List<CharacterProfile> characters = const [],
  }) => _source();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const story = '雨夜，林夏在老街等一个不会来的人。';
  late AppDatabase db;
  late ProjectRepository projects;
  late ShotRepository shots;
  late String projectId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    projects = ProjectRepository(db);
    shots = ShotRepository(db);
    projectId = await projects.create('雨夜重逢');
  });

  tearDown(() => db.close());

  StoryboardController build(Stream<GenerationUpdate> Function() source) => StoryboardController(
    projectId: projectId,
    projects: projects,
    shots: shots,
    api: _FakeApi(source),
  );

  test('生成完成后镜头写入数据库', () async {
    final bloc = build(
      () => Stream.fromIterable(const [
        FirstTokenArrived(Duration(milliseconds: 420)),
        ShotLineArrived(ParsedShot(ShotDraft(index: 0, shotSize: ShotSize.full, scene: '雨夜老街'))),
        GenerationCompleted(),
      ]),
    );
    bloc
      ..add(const StoryChanged(story))
      ..add(const GenerationRequested());

    final done = await bloc.stream.firstWhere((s) => s.phase == GenerationPhase.done);
    expect(done.firstTokenLatency, const Duration(milliseconds: 420));

    final saved = await shots
        .watchByProject(projectId)
        .firstWhere((list) => list.isNotEmpty)
        .timeout(const Duration(seconds: 2));
    expect(saved.single.scene, '雨夜老街');
    await bloc.close();
  });

  test('停止时取消上游订阅，结果不落库', () async {
    final source = StreamController<GenerationUpdate>();
    var upstreamCancelled = false;
    source.onCancel = () => upstreamCancelled = true;

    final bloc = build(() => source.stream);
    bloc
      ..add(const StoryChanged(story))
      ..add(const GenerationRequested());
    source.add(const FirstTokenArrived(Duration(milliseconds: 300)));
    await bloc.stream.firstWhere((s) => s.phase == GenerationPhase.streaming);

    bloc.add(const GenerationCancelled());
    await bloc.stream.firstWhere((s) => s.phase == GenerationPhase.cancelled);
    await Future<void>.delayed(Duration.zero);

    expect(upstreamCancelled, isTrue);
    expect(await shots.loadDrafts(projectId), isEmpty);
    await bloc.close();
    await source.close();
  });
}
