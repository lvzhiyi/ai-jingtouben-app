import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/models/video_platform.dart';
import 'package:jingtouben/data/share/share_api.g.dart';
import 'package:jingtouben/data/share/storyboard_share.dart';
import 'package:jingtouben/data/share/storyboard_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const shot = ShotDraft(
    index: 2,
    shotSize: ShotSize.closeUp,
    scene: '雨夜🌧️',
    dialogue: '回来了。',
    reason: '突出情绪',
    characters: ['林夏', '路人'],
  );

  test('导出角色资料、完整镜头和实时提示词，保留中文和换行', () {
    final text = const StoryboardText().build(
      title: '雨夜重逢',
      shots: [shot],
      characters: const [CharacterProfile(name: '林夏', appearance: '短发', outfit: '红衣')],
      promptsFor: (_) => {VideoPlatform.jimeng: '即梦新衣服\n镜头', VideoPlatform.kling: '可灵雨夜'},
      incomplete: true,
    );
    for (final value in [
      '雨夜重逢',
      '未完整生成',
      '林夏',
      '短发',
      '红衣',
      '#3 · 特写',
      '雨夜🌧️',
      '回来了。',
      '突出情绪',
      '出场：林夏、路人',
      '即梦提示词',
      '即梦新衣服\n镜头',
      '可灵提示词',
      '可灵雨夜',
    ]) {
      expect(text, contains(value));
    }
  });

  test('无镜头拒绝导出；无角色和可选字段仍可导出', () {
    expect(
      () =>
          const StoryboardText().build(title: '', shots: [], characters: [], promptsFor: (_) => {}),
      throwsArgumentError,
    );
    final text = const StoryboardText().build(
      title: ' ',
      shots: const [ShotDraft(index: 0, shotSize: ShotSize.full, scene: '街口')],
      characters: [],
      promptsFor: (_) => {},
    );
    expect(text, startsWith('镜头本'));
    expect(text, contains('街口'));
    expect(text, isNot(contains('未完整生成')));
    expect(text, isNot(contains('角色卡')));
    expect(text, isNot(contains('台词：')));
  });

  const channel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.jingtouben.ShareHostApi.shareText',
    ShareHostApi.pigeonChannelCodec,
  );
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('Android、iOS 通过生成的 Pigeon 通道传递标题和正文', () async {
    final messages = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(channel, (message) async {
          messages.add(message);
          return <Object?>[];
        });
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(await StoryboardShare().share(title: '标题', text: '内容'), ShareResult.presented);
    }
    expect(messages, [
      ['标题', '内容'],
      ['标题', '内容'],
    ]);
  }, skip: kIsWeb);

  test('复制分支把全文交给剪贴板，并只在写入成功后返回 copied', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    expect(await StoryboardShare().share(title: '标题', text: '分镜全文'), ShareResult.copied);
    if (kIsWeb) {
      // 浏览器即使运行在 Android，也必须走剪贴板。
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await StoryboardShare().share(title: '标题', text: '分镜全文'), ShareResult.copied);
      calls.removeLast();
    }
    expect(calls.single.method, 'Clipboard.setData');
    expect(calls.single.arguments, {'text': '分镜全文'});
  });

  test('原生失败和剪贴板失败保留异常供界面提示，不误报成功', () async {
    if (!kIsWeb) {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            channel,
            (_) async => ['share_failed', 'failed', null],
          );
      await expectLater(
        StoryboardShare().share(title: '标题', text: '内容'),
        throwsA(isA<PlatformException>()),
      );
    }
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => throw PlatformException(code: 'denied'),
    );
    await expectLater(
      StoryboardShare().share(title: '标题', text: '内容'),
      throwsA(isA<PlatformException>()),
    );
  });
}
