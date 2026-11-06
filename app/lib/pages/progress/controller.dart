import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/character_profile.dart';
import '../../data/models/shot_status.dart';
import '../../data/models/video_platform.dart';
import '../../data/prompt/template_repository.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/progress_repository.dart';
import 'state.dart';

/// 订阅镜头与生成记录、角色卡；记录、选定、删除后由数据库推送新列表，不手动刷新。
class ProgressController extends Cubit<ProgressState> {
  ProgressController({
    required this.projectId,
    required this._progress,
    required CharacterRepository characters,
    required TemplateRepository templates,
  }) : super(const ProgressState()) {
    _shotsSubscription = _progress
        .watchProject(projectId)
        .listen((shots) => emit(state.copyWith(loading: false, shots: shots)));
    _charactersSubscription = characters
        .watchProfiles(projectId)
        .listen((profiles) => emit(state.copyWith(characters: profiles)));
    unawaited(_loadTemplates(templates));
  }

  final String projectId;
  final ProgressRepository _progress;
  late final StreamSubscription<List<ShotProgress>> _shotsSubscription;
  late final StreamSubscription<List<CharacterProfile>> _charactersSubscription;

  Future<void> _loadTemplates(TemplateRepository templates) async {
    try {
      // 先等加载完再读 state，理由同分镜页
      final loaded = await templates.load();
      if (!isClosed) emit(state.copyWith(templates: loaded));
    } on StateError {
      // 只有内置模板损坏才会失败；此时不能记录生成，页面给出提示。
    }
  }

  void setFilter(ShotStatus? filter) => emit(state.copyWith(filter: () => filter));

  /// 记一次生成，提示词快照取这一刻按当前角色卡拼出的写法。模板未加载时不记录。
  Future<bool> record(String shotId, VideoPlatform platform, {String note = ''}) async {
    final shot = state.shots.where((item) => item.shotId == shotId).firstOrNull;
    final prompt = shot == null ? null : state.promptsFor(shot.shot)[platform];
    if (prompt == null) return false;
    await _progress.record(shotId: shotId, platform: platform, prompt: prompt, note: note);
    return true;
  }

  Future<void> togglePick(String generationId) => _progress.togglePick(generationId);

  Future<void> updateNote(String generationId, String note) =>
      _progress.updateNote(generationId, note);

  Future<void> delete(String generationId) => _progress.delete(generationId);

  @override
  Future<void> close() async {
    // 两个订阅同时取消；依次 await 的话第二个要等第一个在 drift 里收尾后才开始
    await Future.wait([_shotsSubscription.cancel(), _charactersSubscription.cancel()]);
    return super.close();
  }
}
