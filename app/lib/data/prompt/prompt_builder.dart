import '../models/character_profile.dart';
import '../models/shot_size.dart';
import 'prompt_template.dart';

/// 按「镜头 + 角色卡 + 平台模板」实时拼接提示词。
///
/// 结果不落库：角色卡改一处，所有镜头的提示词自动更新；模板升级后旧镜头也用新写法。
class PromptBuilder {
  const PromptBuilder();

  String build({
    required PromptTemplate template,
    required ShotSize shotSize,
    required String scene,
    String dialogue = '',
    List<CharacterProfile> characters = const [],
  }) {
    final characterText = characters
        .map(
          (c) => render(template.character, {
            'name': c.name,
            'appearance': c.appearance,
            'outfit': c.outfit,
          }),
        )
        .where((text) => text.isNotEmpty)
        .join(template.separator);
    return render(template.shot, {
      'shotSize': shotSize.label,
      'scene': scene,
      'dialogue': dialogue,
      'characters': characterText,
    });
  }

  static final _optional = RegExp(r'\[([^\[\]]*)\]');
  static final _variable = RegExp(r'\{(\w+)\}');

  /// 渲染模板：先处理可选片段，再替换变量。
  static String render(String template, Map<String, String> values) {
    String valueOf(String name) => values[name]?.trim() ?? '';
    final kept = template.replaceAllMapped(_optional, (match) {
      final segment = match.group(1)!;
      final filled = _variable
          .allMatches(segment)
          .every((variable) => valueOf(variable.group(1)!).isNotEmpty);
      return filled ? segment : '';
    });
    return kept.replaceAllMapped(_variable, (match) => valueOf(match.group(1)!)).trim();
  }
}
