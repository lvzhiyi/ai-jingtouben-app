import 'package:equatable/equatable.dart';

import '../models/video_platform.dart';

/// 某个视频平台的提示词模板，由服务端下发。
///
/// 语法：`{变量}` 替换为字段值；`[片段]` 里只要有一个变量为空，整段省略。
class PromptTemplate extends Equatable {
  const PromptTemplate({
    required this.platform,
    required this.version,
    required this.shot,
    required this.character,
    this.separator = '；',
  });

  final VideoPlatform platform;
  final int version;

  /// 镜头模板，可用变量：shotSize、scene、dialogue、characters。
  final String shot;

  /// 单个角色的模板，可用变量：name、appearance、outfit。
  final String character;

  /// 多个角色之间的分隔符。
  final String separator;

  /// 解析失败返回 null，例如新版服务端下发了客户端还不认识的平台。
  static PromptTemplate? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final platform = VideoPlatform.tryParse(json['platform']);
    final version = json['version'];
    final shot = json['shot'];
    final character = json['character'];
    if (platform == null || version is! int || shot is! String || character is! String) {
      return null;
    }
    final separator = json['separator'];
    return PromptTemplate(
      platform: platform,
      version: version,
      shot: shot,
      character: character,
      separator: separator is String ? separator : '；',
    );
  }

  @override
  List<Object?> get props => [platform, version, shot, character, separator];
}

/// 一组模板及其整体版本号。
class PromptTemplateSet extends Equatable {
  const PromptTemplateSet({required this.version, required this.templates});

  final int version;
  final Map<VideoPlatform, PromptTemplate> templates;

  static PromptTemplateSet? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final version = json['version'];
    final list = json['templates'];
    if (version is! int || list is! List<dynamic>) return null;
    final templates = <VideoPlatform, PromptTemplate>{};
    for (final item in list) {
      final template = PromptTemplate.tryParse(item);
      if (template != null) templates[template.platform] = template;
    }
    return templates.isEmpty ? null : PromptTemplateSet(version: version, templates: templates);
  }

  @override
  List<Object?> get props => [version, templates];
}
