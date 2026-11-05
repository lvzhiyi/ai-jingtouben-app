import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/share/storyboard_json.dart';

void main() {
  const shots = [
    ShotDraft(index: 0, shotSize: ShotSize.extremeLong, scene: '雨夜街道'),
    ShotDraft(
      index: 2,
      shotSize: ShotSize.closeUp,
      scene: '雨夜🌧️',
      dialogue: '回来了。',
      reason: '突出情绪',
      characters: ['林夏', '路人'],
      warnings: ['景别兜底'],
    ),
  ];

  Map<String, dynamic> build({String title = ' 雨夜重逢 ', bool incomplete = false}) => jsonDecode(
    const StoryboardJson().build(
      title: title,
      story: ' 林夏深夜下班。 ',
      shots: shots,
      characters: const [CharacterProfile(name: '林夏', appearance: '短发', outfit: '红衣')],
      incomplete: incomplete,
    ),
  ) as Map<String, dynamic>;

  test('按 ai-tools studio import 的格式导出项目、角色卡和镜头', () {
    expect(build(), {
      'format': 'jingtouben.storyboard',
      'version': 1,
      'project': {'title': '雨夜重逢', 'story': '林夏深夜下班。'},
      'characters': [
        {'name': '林夏', 'appearance': '短发', 'outfit': '红衣'},
      ],
      'shots': [
        {
          'order': 1,
          'shotSize': 'extremeLong',
          'scene': '雨夜街道',
          'dialogue': '',
          'reason': '',
          'characters': <String>[],
        },
        {
          'order': 3,
          'shotSize': 'closeUp',
          'scene': '雨夜🌧️',
          'dialogue': '回来了。',
          'reason': '突出情绪',
          'characters': ['林夏', '路人'],
        },
      ],
    });
  });

  test('未完整生成时标注；空标题兜底；没有镜头报错', () {
    expect(build(incomplete: true)['incomplete'], isTrue);
    expect(build(title: '  ')['project']['title'], '镜头本');
    expect(
      () => const StoryboardJson().build(
        title: 't',
        story: '',
        shots: const [],
        characters: const [],
      ),
      throwsArgumentError,
    );
  });
}
