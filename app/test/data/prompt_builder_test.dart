import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/models/video_platform.dart';
import 'package:jingtouben/data/prompt/prompt_builder.dart';
import 'package:jingtouben/data/prompt/prompt_template.dart';

void main() {
  const builder = PromptBuilder();
  const template = PromptTemplate(
    platform: VideoPlatform.jimeng,
    version: 1,
    shot: '{shotSize}，{scene}[。人物：{characters}][。台词：“{dialogue}”]',
    character: '{name}[，{appearance}][，穿{outfit}]',
  );

  test('角色卡注入提示词，空的可选片段整段省略', () {
    final prompt = builder.build(
      template: template,
      shotSize: ShotSize.medium,
      scene: '林夏回头',
      characters: const [
        CharacterProfile(name: '林夏', appearance: '短发', outfit: '米色风衣'),
        CharacterProfile(name: '陈默'),
      ],
    );
    expect(prompt, '中景，林夏回头。人物：林夏，短发，穿米色风衣；陈默');
  });

  test('有台词时保留台词片段', () {
    final prompt = builder.build(
      template: template,
      shotSize: ShotSize.closeUp,
      scene: '手机屏幕',
      dialogue: '我到了',
    );
    expect(prompt, '特写，手机屏幕。台词：“我到了”');
  });

  test('模板 JSON 解析会跳过不认识的平台', () {
    final set = PromptTemplateSet.tryParse({
      'version': 3,
      'templates': [
        {'platform': 'kling', 'version': 1, 'shot': '{scene}', 'character': '{name}'},
        {'platform': 'unknown', 'version': 1, 'shot': '{scene}', 'character': '{name}'},
      ],
    });
    expect(set?.version, 3);
    expect(set?.templates.keys.toList(), [VideoPlatform.kling]);
  });
}
