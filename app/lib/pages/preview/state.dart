import 'package:equatable/equatable.dart';

import '../../data/models/shot_draft.dart';
import '../../data/models/shot_duration.dart';

/// 预演的离散状态：第几镜、在不在播、是否播完。
///
/// 镜头内的连续进度不放在这里，由页面的 AnimationController 驱动，避免每帧 emit、整页重建。
class PreviewState extends Equatable {
  const PreviewState({
    this.loading = true,
    this.shots = const [],
    this.index = 0,
    this.playing = false,
    this.finished = false,
    this.showScene = true,
    this.cue = 0,
  });

  final bool loading;
  final List<ShotDraft> shots;

  /// 当前镜头在 [shots] 中的位置（不是镜头序号：坏行没有落库，序号可能不连续）。
  final int index;
  final bool playing;

  /// 最后一镜播完，停在最后一帧。
  final bool finished;

  /// 是否在画框上方显示画面描述。
  final bool showScene;

  /// 每次换镜或重新开始一镜时加 1，页面据此把镜头内进度归零（同一镜重播时 [index] 不变）。
  final int cue;

  ShotDraft? get current => shots.isEmpty ? null : shots[index];

  bool get isLast => index == shots.length - 1;

  int get totalMs => shots.fold(0, (sum, shot) => sum + shot.effectiveDurationMs);

  /// 当前镜头开始前已经过去的时长。
  int get startMs => shots.take(index).fold(0, (sum, shot) => sum + shot.effectiveDurationMs);

  PreviewState copyWith({
    bool? loading,
    List<ShotDraft>? shots,
    int? index,
    bool? playing,
    bool? finished,
    bool? showScene,
    int? cue,
  }) => PreviewState(
    loading: loading ?? this.loading,
    shots: shots ?? this.shots,
    index: index ?? this.index,
    playing: playing ?? this.playing,
    finished: finished ?? this.finished,
    showScene: showScene ?? this.showScene,
    cue: cue ?? this.cue,
  );

  @override
  List<Object?> get props => [loading, shots, index, playing, finished, showScene, cue];
}
