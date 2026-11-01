import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/character_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/prompt/template_repository.dart';
import '../../data/repositories/shot_repository.dart';
import '../../data/storyboard/shot_line_parser.dart';
import '../../data/storyboard/storyboard_api.dart';
import '../../net/api_exception.dart';
import 'state.dart';

sealed class StoryboardEvent extends Equatable {
  const StoryboardEvent();

  @override
  List<Object?> get props => [];
}

/// 进入页面：读取项目、已保存的镜头和提示词模板，并订阅角色卡。
final class StoryboardOpened extends StoryboardEvent {
  const StoryboardOpened();
}

final class StoryChanged extends StoryboardEvent {
  const StoryChanged(this.story);

  final String story;

  @override
  List<Object?> get props => [story];
}

/// 生成相关的事件共用一个处理器，并使用 restartable：新事件到来时自动取消上一次生成。
/// 「重新生成」和「停止」因此都不需要手动管理订阅。
sealed class GenerationEvent extends StoryboardEvent {
  const GenerationEvent();
}

final class GenerationRequested extends GenerationEvent {
  const GenerationRequested();
}

final class GenerationCancelled extends GenerationEvent {
  const GenerationCancelled();
}

class StoryboardController extends Bloc<StoryboardEvent, StoryboardState> {
  StoryboardController({
    required this.projectId,
    required this._projects,
    required this._shots,
    required this._characters,
    required this._templates,
    required this._api,
  }) : super(const StoryboardState()) {
    on<StoryboardOpened>(_onOpened);
    on<StoryChanged>(_onStoryChanged, transformer: restartable());
    on<GenerationEvent>(_onGeneration, transformer: restartable());
  }

  final String projectId;
  final ProjectRepository _projects;
  final ShotRepository _shots;
  final CharacterRepository _characters;
  final TemplateRepository _templates;
  final StoryboardApi _api;

  /// 输入停顿后才写库；新的输入会取消上一次等待。
  static const storySaveDelay = Duration(milliseconds: 500);

  /// 最近一次写进数据库的故事，用来判断离开页面时是否还有没保存的修改。
  String? _savedStory;

  Future<void> _onOpened(StoryboardOpened event, Emitter<StoryboardState> emit) async {
    final project = await _projects.find(projectId);
    _savedStory = project?.story ?? '';
    final drafts = await _shots.loadDrafts(projectId);
    emit(
      state.copyWith(
        loaded: true,
        title: project?.title ?? '',
        story: project?.story ?? '',
        items: [for (final draft in drafts) ParsedShot(draft)],
        phase: drafts.isEmpty ? GenerationPhase.idle : GenerationPhase.done,
      ),
    );

    // 模板有服务端 → 缓存 → 内置三级兜底，只有内置文件损坏才会失败；失败时镜头卡不显示提示词。
    try {
      // 先等加载完再读 state：写成 state.copyWith(templates: await ...) 会在等待前就取走旧 state，
      // 覆盖掉等待期间用户输入的故事
      final templates = await _templates.load();
      emit(state.copyWith(templates: templates));
    } on StateError {
      // 忽略，见上
    }

    // 页面存续期间一直订阅：角色页里改了外貌服装，返回时提示词已经是新的。
    await emit.forEach(
      _characters.watchProfiles(projectId),
      onData: (characters) => state.copyWith(characters: characters),
    );
  }

  Future<void> _onStoryChanged(StoryChanged event, Emitter<StoryboardState> emit) async {
    emit(state.copyWith(story: event.story));
    await Future<void>.delayed(storySaveDelay);
    // restartable 取消的是事件订阅，已经开始的 await 仍会返回，这里要自己判断
    if (emit.isDone) return;
    await _saveStory();
  }

  Future<void> _saveStory() async {
    final story = state.story;
    if (_savedStory == null || story == _savedStory) return;
    await _projects.updateStory(projectId, story);
    _savedStory = story;
  }

  Future<void> _onGeneration(GenerationEvent event, Emitter<StoryboardState> emit) async {
    switch (event) {
      case GenerationCancelled():
        // restartable 已经取消了上一次生成的订阅，连接随之断开；这里只更新状态。
        if (state.phase.isActive) {
          emit(state.copyWith(phase: GenerationPhase.cancelled, drafting: () => null));
        }
      case GenerationRequested():
        await _generate(emit);
    }
  }

  Future<void> _generate(Emitter<StoryboardState> emit) async {
    final story = state.story.trim();
    if (story.length < StoryboardState.minStoryLength) return;

    emit(
      state.copyWith(
        phase: GenerationPhase.connecting,
        items: const [],
        drafting: () => null,
        firstTokenLatency: () => null,
        error: () => null,
      ),
    );
    await _saveStory();
    // 每次生成时现读角色卡，角色页的修改不需要通知分镜页。
    final characters = await _characters.loadProfiles(projectId);

    try {
      await emit.forEach<GenerationUpdate>(
        _api.generate(story: story, characters: characters),
        onData: (update) => switch (update) {
          FirstTokenArrived(:final latency) => state.copyWith(
            phase: GenerationPhase.streaming,
            firstTokenLatency: () => latency,
          ),
          ShotDrafting(:final shot) => state.copyWith(drafting: () => shot),
          ShotLineArrived(:final result) => state.copyWith(
            items: [...state.items, result],
            drafting: () => null,
          ),
          GenerationCompleted() => state.copyWith(
            phase: GenerationPhase.done,
            drafting: () => null,
          ),
        },
      );
    } on ApiException catch (error) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            phase: GenerationPhase.failed,
            drafting: () => null,
            error: () => error.kind,
          ),
        );
      }
      return;
    }

    // 被取消或中途失败时不落库，保留上一次完整的结果。
    if (emit.isDone || state.phase != GenerationPhase.done) return;
    await _shots.replaceAll(projectId, state.drafts);
  }

  /// 离开页面时把停顿期内还没写库的故事存下来。
  @override
  Future<void> close() async {
    await _saveStory();
    return super.close();
  }
}
