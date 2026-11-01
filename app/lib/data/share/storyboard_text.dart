import '../models/character_profile.dart';
import '../models/shot_draft.dart';
import '../models/video_platform.dart';

/// 导出本次页面快照；提示词由调用方按当前角色和模板实时拼接。
class StoryboardText {
  const StoryboardText();

  String build({
    required String title,
    required List<ShotDraft> shots,
    required List<CharacterProfile> characters,
    required Map<VideoPlatform, String> Function(ShotDraft) promptsFor,
    bool incomplete = false,
  }) {
    if (shots.isEmpty) throw ArgumentError('没有可分享的镜头');
    final text = StringBuffer(title.trim().isEmpty ? '镜头本' : title.trim());
    text.writeln('\n镜头本 · 共 ${shots.length} 个镜头');
    if (incomplete) text.writeln('注意：本次分镜未完整生成，仅包含已收到的有效镜头。');
    if (characters.isNotEmpty) {
      text.writeln('\n角色卡');
      for (final character in characters) {
        text.writeln('姓名：${character.name}');
        if (character.appearance.isNotEmpty) text.writeln('外貌：${character.appearance}');
        if (character.outfit.isNotEmpty) text.writeln('服装：${character.outfit}');
        text.writeln();
      }
    }
    for (final shot in shots) {
      text.writeln('\n#${shot.index + 1} · ${shot.shotSize.label}');
      text.writeln('画面：${shot.scene}');
      if (shot.dialogue.isNotEmpty) text.writeln('台词：${shot.dialogue}');
      if (shot.characters.isNotEmpty) text.writeln('出场：${shot.characters.join('、')}');
      if (shot.reason.isNotEmpty) text.writeln('为什么这样拍：${shot.reason}');
      for (final entry in promptsFor(shot).entries) {
        text.writeln('\n${entry.key.label}提示词：\n${entry.value}');
      }
    }
    return text.toString().trimRight();
  }
}
