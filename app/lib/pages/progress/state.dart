import 'package:equatable/equatable.dart';

import '../../data/models/character_profile.dart';
import '../../data/models/shot_draft.dart';
import '../../data/models/shot_status.dart';
import '../../data/models/video_platform.dart';
import '../../data/prompt/prompt_builder.dart';
import '../../data/prompt/prompt_template.dart';
import '../../data/repositories/progress_repository.dart';

class ProgressState extends Equatable {
  const ProgressState({
    this.loading = true,
    this.shots = const [],
    this.filter,
    this.characters = const [],
    this.templates,
  });

  /// 数据库第一次推送之前为 true，用来区分「加载中」和「还没有分镜」。
  final bool loading;
  final List<ShotProgress> shots;

  /// 只看某一种状态；null 为全部。
  final ShotStatus? filter;

  final List<CharacterProfile> characters;

  /// 提示词模板；加载完成前为 null，此时不能记录生成（没有提示词快照）。
  final PromptTemplateSet? templates;

  List<ShotProgress> get visible => filter == null
      ? shots
      : [
          for (final shot in shots)
            if (shot.status == filter) shot,
        ];

  int count(ShotStatus status) => shots.where((shot) => shot.status == status).length;

  /// 已选定的镜头占比，0–1。
  double get pickedRatio => shots.isEmpty ? 0 : count(ShotStatus.picked) / shots.length;

  /// 和分镜页同一套拼法，见 [PromptBuilder.buildAll]。
  Map<VideoPlatform, String> promptsFor(ShotDraft shot) {
    final templates = this.templates;
    if (templates == null) return const {};
    return const PromptBuilder().buildAll(templates: templates, shot: shot, characters: characters);
  }

  /// [filter] 用函数包一层，以便显式置空。
  ProgressState copyWith({
    bool? loading,
    List<ShotProgress>? shots,
    ShotStatus? Function()? filter,
    List<CharacterProfile>? characters,
    PromptTemplateSet? templates,
  }) => ProgressState(
    loading: loading ?? this.loading,
    shots: shots ?? this.shots,
    filter: filter == null ? this.filter : filter(),
    characters: characters ?? this.characters,
    templates: templates ?? this.templates,
  );

  @override
  List<Object?> get props => [loading, shots, filter, characters, templates];
}
