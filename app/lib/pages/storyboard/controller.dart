import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/character_repository.dart';
import '../../data/repositories/project_repository.dart';
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

/// 进入页面：读取项目和已保存的镜头。
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
    required this._api,
  }) : super(const StoryboardState()) {
    on<StoryboardOpened>(_onOpened);
    on<StoryChanged>((event, emit) => emit(state.copyWith(story: event.story)));
    on<GenerationEvent>(_onGeneration, transformer: restartable());
  }

  final String projectId;
  final ProjectRepository _projects;
  final ShotRepository _shots;
  final CharacterRepository _characters;
  final StoryboardApi _api;

  Future<void> _onOpened(StoryboardOpened event, Emitter<StoryboardState> emit) async {
    final project = await _projects.find(projectId);
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
    await _projects.updateStory(projectId, story);
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
}
