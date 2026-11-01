import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/prompt/prompt_template.dart';
import 'package:jingtouben/data/share/storyboard_share.dart';
import 'package:jingtouben/data/storyboard/shot_line_parser.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/storyboard/controller.dart';
import 'package:jingtouben/pages/storyboard/state.dart';
import 'package:jingtouben/pages/storyboard/widgets/share_button.dart';

import '../helpers/test_env.dart';

class _Api implements StoryboardApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Share extends StoryboardShare {
  int calls = 0;
  String text = '';
  Completer<ShareResult> pending = Completer<ShareResult>();
  @override
  Future<ShareResult> share({required String title, required String text}) {
    calls++;
    this.text = text;
    return pending.future;
  }
}

void main() {
  late TestEnv env;
  late StoryboardController controller;
  late _Share share;
  late StoryboardState ready;
  setUp(() {
    env = TestEnv(api: _Api());
    controller = StoryboardController(
      projectId: 'test',
      projects: env.projects,
      shots: env.shots,
      characters: env.characters,
      templates: env.templates,
      api: env.api,
    );
    share = _Share();
    ready = StoryboardState(
      loaded: true,
      title: '雨夜',
      phase: GenerationPhase.done,
      templates: PromptTemplateSet.tryParse(jsonDecode(testTemplates))!,
      characters: const [CharacterProfile(name: '林夏', outfit: '红衣')],
      items: const [
        ParsedShot(ShotDraft(index: 0, shotSize: ShotSize.full, scene: '街口', characters: ['林夏'])),
        BrokenShot(index: 1, raw: '坏内容', reason: '坏行'),
      ],
    );
  });
  tearDown(() async {
    await controller.close();
    await env.db.close();
  });

  Future<void> pump(WidgetTester tester, StoryboardState state) async {
    share.pending = Completer<ShareResult>();
    // 使用真实 Bloc，仅直接输入页面状态快照，不替换状态逻辑。
    // ignore: invalid_use_of_visible_for_testing_member
    controller.emit(state);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: controller,
          child: Scaffold(
            appBar: AppBar(actions: [ShareButton(share: share)]),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('未加载、无镜头、缺模板和生成中禁止分享', (tester) async {
    for (final state in [
      const StoryboardState(),
      ready.copyWith(items: []),
      StoryboardState(loaded: true, items: ready.items),
      ready.copyWith(phase: GenerationPhase.connecting),
      ready.copyWith(phase: GenerationPhase.streaming),
    ]) {
      await pump(tester, state);
      expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    }
    expect(share.calls, 0);
  });

  testWidgets('分享快照含最新提示词，过滤坏行，防连点，复制成功后提示', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byTooltip('分享分镜'));
    await tester.pump();
    expect(share.calls, 1);
    expect(share.text, contains('即梦提示词：\n全景，街口。人物：林夏，穿红衣'));
    expect(share.text, contains('可灵提示词：\n街口，全景'));
    expect(share.text, contains('未完整生成'));
    expect(share.text, isNot(contains('坏内容')));
    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
    share.pending.complete(ShareResult.copied);
    await tester.pumpAndSettle();
    expect(find.text('分镜已复制'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNotNull);
  });

  testWidgets('失败可以重试；面板展示后不宣称发送成功', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byTooltip('分享分镜'));
    share.pending.completeError(PlatformException(code: 'share_failed'));
    await tester.pumpAndSettle();
    expect(find.text('分享失败，请重试'), findsOneWidget);
    share.pending = Completer<ShareResult>();
    await tester.tap(find.byTooltip('分享分镜'));
    share.pending.complete(ShareResult.presented);
    await tester.pumpAndSettle();
    expect(share.calls, 2);
    expect(find.text('分享成功'), findsNothing);
  });

  testWidgets('分享等待期间离开页面安全结束', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byTooltip('分享分镜'));
    await tester.pumpWidget(const SizedBox());
    share.pending.complete(ShareResult.copied);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
