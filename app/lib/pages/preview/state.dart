import 'package:equatable/equatable.dart';

import '../../data/models/prop_drawing.dart';

import '../../data/models/shot_draft.dart';
import '../../data/models/shot_duration.dart';
import '../../data/repositories/prop_repository.dart';

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
    this.propRecords = const {},
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

  /// 镜头里用到的生成道具的缓存记录；没有记录的道具还在生成（或排在后面），画占位。
  final Map<String, PropRecord> propRecords;

  ShotDraft? get current => shots.isEmpty ? null : shots[index];

  /// 已经画好的生成道具。
  Map<String, PropDrawing> get propDrawings => {
    for (final MapEntry(:key, :value) in propRecords.entries) key: ?value.drawing,
  };

  /// 当前镜头里的生成道具名（去掉内置的），重画面板用。
  List<String> get currentGeneratedProps => <String>{
    for (final prop in current?.shotProps ?? const [])
      if (!isBuiltinProp(prop.name)) prop.name,
  }.toList();

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
    Map<String, PropRecord>? propRecords,
  }) => PreviewState(
    loading: loading ?? this.loading,
    shots: shots ?? this.shots,
    index: index ?? this.index,
    playing: playing ?? this.playing,
    finished: finished ?? this.finished,
    showScene: showScene ?? this.showScene,
    cue: cue ?? this.cue,
    propRecords: propRecords ?? this.propRecords,
  );

  @override
  List<Object?> get props => [
    loading,
    shots,
    index,
    playing,
    finished,
    showScene,
    cue,
    propRecords,
  ];
}
