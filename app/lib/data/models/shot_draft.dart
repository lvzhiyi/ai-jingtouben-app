import 'package:equatable/equatable.dart';

import 'camera_move.dart';
import 'shot_prop.dart';
import 'shot_size.dart';

/// 一个镜头的内容，来自流式解析或本地存储；不包含进度和生成记录。
class ShotDraft extends Equatable {
  const ShotDraft({
    required this.index,
    required this.shotSize,
    required this.scene,
    this.dialogue = '',
    this.reason = '',
    this.characters = const [],
    this.cameraMove = CameraMove.fixed,
    this.durationMs,
    this.shotProps,
    this.warnings = const [],
  });

  /// 镜头序号，从 0 开始。
  final int index;
  final ShotSize shotSize;
  final String scene;
  final String dialogue;

  /// 为什么这样拍：面向新手的镜头语言解释。
  final String reason;

  /// 出场角色名，后续按名称匹配角色卡。
  final List<String> characters;

  final CameraMove cameraMove;

  /// 时长（毫秒）。为空表示模型没给或旧数据，使用时按默认规则推导（见 `shot_duration.dart`）。
  final int? durationMs;

  /// 镜头里的道具。为空表示旧数据或模型没给，预演按画面描述的关键词兜底；空列表表示没有道具。
  final List<ShotProp>? shotProps;

  /// 字段校验时做过的兜底，展示给用户确认；不落库。
  final List<String> warnings;

  @override
  List<Object?> get props => [
    index,
    shotSize,
    scene,
    dialogue,
    reason,
    characters,
    cameraMove,
    durationMs,
    shotProps,
    warnings,
  ];
}
