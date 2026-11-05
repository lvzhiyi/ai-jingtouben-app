import 'dart:convert';

import '../models/character_profile.dart';
import '../models/shot_draft.dart';

/// 导出给 ai-tools（本地 AI 短剧流水线）的结构化分镜，由 `studio import` 读入。
///
/// 只导出整理好的原始内容（故事、角色卡、镜头），不含即梦／可灵提示词：
/// 那边会按自己的出图模型重新写英文提示词。字段名对应 drift 表，格式改动时升 [version]。
class StoryboardJson {
  const StoryboardJson();

  static const format = 'jingtouben.storyboard';
  static const version = 1;

  String build({
    required String title,
    required String story,
    required List<ShotDraft> shots,
    required List<CharacterProfile> characters,
    bool incomplete = false,
  }) {
    if (shots.isEmpty) throw ArgumentError('没有可导出的镜头');
    final data = {
      'format': format,
      'version': version,
      'project': {'title': title.trim().isEmpty ? '镜头本' : title.trim(), 'story': story.trim()},
      if (incomplete) 'incomplete': true,
      'characters': [for (final character in characters) character.toJson()],
      'shots': [
        for (final shot in shots)
          {
            'order': shot.index + 1,
            'shotSize': shot.shotSize.name,
            'scene': shot.scene,
            'dialogue': shot.dialogue,
            'reason': shot.reason,
            'characters': shot.characters,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
