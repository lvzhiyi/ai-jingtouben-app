import 'package:equatable/equatable.dart';

import '../../data/models/shot_draft.dart';
import '../../data/storyboard/shot_line_parser.dart';
import '../../net/api_exception.dart';

/// 一次生成的阶段。流式生成要区分的状态多，这也是选 BLoC 的原因之一。
enum GenerationPhase {
  idle,
  connecting,
  streaming,
  done,
  cancelled,
  failed;

  bool get isActive => this == connecting || this == streaming;
}

class StoryboardState extends Equatable {
  const StoryboardState({
    this.loaded = false,
    this.title = '',
    this.story = '',
    this.phase = GenerationPhase.idle,
    this.items = const [],
    this.drafting,
    this.firstTokenLatency,
    this.error,
  });

  /// 与服务端校验保持一致。
  static const minStoryLength = 10;

  final bool loaded;
  final String title;
  final String story;
  final GenerationPhase phase;

  /// 当前展示的镜头。流式过程中逐行追加；坏行留在原位置，提示需要重新生成。
  final List<ShotLineResult> items;

  /// 正在生成、还没写完的下一个镜头；只在生成过程中存在。
  final PartialShot? drafting;

  /// 最近一次生成的首字延迟。
  final Duration? firstTokenLatency;
  final ApiErrorKind? error;

  bool get canGenerate => !phase.isActive && story.trim().length >= minStoryLength;

  List<ShotDraft> get drafts => [
    for (final item in items)
      if (item is ParsedShot) item.shot,
  ];

  /// 可空字段用函数包一层，以便显式置空。
  StoryboardState copyWith({
    bool? loaded,
    String? title,
    String? story,
    GenerationPhase? phase,
    List<ShotLineResult>? items,
    PartialShot? Function()? drafting,
    Duration? Function()? firstTokenLatency,
    ApiErrorKind? Function()? error,
  }) => StoryboardState(
    loaded: loaded ?? this.loaded,
    title: title ?? this.title,
    story: story ?? this.story,
    phase: phase ?? this.phase,
    items: items ?? this.items,
    drafting: drafting == null ? this.drafting : drafting(),
    firstTokenLatency: firstTokenLatency == null ? this.firstTokenLatency : firstTokenLatency(),
    error: error == null ? this.error : error(),
  );

  @override
  List<Object?> get props => [
    loaded,
    title,
    story,
    phase,
    items,
    drafting,
    firstTokenLatency,
    error,
  ];
}
