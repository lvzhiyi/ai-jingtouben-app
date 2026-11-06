import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/shot_repository.dart';
import 'state.dart';

/// 预演的播放逻辑：读入已保存的镜头，管理第几镜、播放 / 暂停和播完。
///
/// 镜头内计时由页面负责，播完一镜时调用 [next]。
class PreviewController extends Cubit<PreviewState> {
  PreviewController({required this.projectId, required this._shots, this.startShot})
    : super(const PreviewState());

  final String projectId;
  final ShotRepository _shots;

  /// 从哪个镜头开始，取镜头序号（`ShotDraft.index`）；为空或找不到时从第一镜开始。
  final int? startShot;

  Future<void> load() async {
    final shots = await _shots.loadDrafts(projectId);
    if (isClosed) return;
    final start = shots.indexWhere((shot) => shot.index == startShot);
    emit(
      state.copyWith(
        loading: false,
        shots: shots,
        index: start < 0 ? 0 : start,
        playing: shots.isNotEmpty,
        cue: state.cue + 1,
      ),
    );
  }

  void play() {
    if (state.shots.isEmpty) return;
    if (state.finished) return replay();
    emit(state.copyWith(playing: true));
  }

  void pause() => emit(state.copyWith(playing: false));

  void togglePlay() => state.playing ? pause() : play();

  /// 下一镜；已经是最后一镜时停在最后一帧。
  void next() {
    if (state.shots.isEmpty || state.finished) return;
    if (state.isLast) {
      emit(state.copyWith(playing: false, finished: true));
    } else {
      _jump(state.index + 1);
    }
  }

  /// 上一镜；已经是第一镜时从头重播这一镜。
  void previous() {
    if (state.shots.isEmpty) return;
    _jump(state.index > 0 ? state.index - 1 : 0);
  }

  /// 跳到第 [index] 个镜头（列表位置）并播放。
  void seek(int index) {
    if (index < 0 || index >= state.shots.length) return;
    _jump(index, playing: true);
  }

  void replay() {
    if (state.shots.isEmpty) return;
    _jump(0, playing: true);
  }

  void toggleScene() => emit(state.copyWith(showScene: !state.showScene));

  void _jump(int index, {bool? playing}) =>
      emit(state.copyWith(index: index, finished: false, playing: playing, cue: state.cue + 1));
}
