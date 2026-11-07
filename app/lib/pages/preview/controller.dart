import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/prop_drawing.dart';
import '../../data/props/prop_generator.dart';
import '../../data/repositories/prop_repository.dart';
import '../../data/repositories/shot_repository.dart';
import 'state.dart';

/// 预演的播放逻辑：读入已保存的镜头，管理第几镜、播放 / 暂停和播完。
///
/// 镜头内计时由页面负责，播完一镜时调用 [next]。
class PreviewController extends Cubit<PreviewState> {
  PreviewController({
    required this.projectId,
    required this._shots,
    required this._props,
    required this._generator,
    this.startShot,
  }) : super(const PreviewState());

  final String projectId;
  final ShotRepository _shots;
  final PropRepository _props;
  final PropGenerator _generator;
  StreamSubscription<Map<String, PropRecord>>? _propsSubscription;

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
    _watchProps();
  }

  /// 镜头里用到的生成道具（按出现顺序，去掉内置的）：监听缓存，没画过的请求生成。
  /// 生成在后台进行，预演不等它，画好后缓存变化、画面替换占位。
  void _watchProps() {
    // 集合字面量保持插入顺序，即出现顺序
    final names = <String>{
      for (final shot in state.shots)
        for (final prop in shot.shotProps ?? const [])
          if (!isBuiltinProp(prop.name)) prop.name,
    }.toList();
    if (names.isEmpty) return;
    _propsSubscription = _props.watch(names).listen((records) {
      if (!isClosed) emit(state.copyWith(propRecords: records));
    });
    unawaited(_generator.ensure(names));
  }

  /// 重画一个道具：删缓存、重新生成，所有剧本里的这个道具一起变。
  Future<void> redraw(String name) => _generator.redraw(name);

  @override
  Future<void> close() async {
    await _propsSubscription?.cancel();
    return super.close();
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
