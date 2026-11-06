import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/progress_repository.dart';
import '../../resources/theme.dart';
import 'controller.dart';
import 'state.dart';
import 'widgets/generation_detail_dialog.dart';
import 'widgets/progress_shot_tile.dart';
import 'widgets/progress_summary.dart';
import 'widgets/record_generation_dialog.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ProgressController, ProgressState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('镜头进度板')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                if (state.loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.shots.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.all(AppUi.pagePadding),
                    sliver: SliverToBoxAdapter(child: _EmptyBoard()),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 8, AppUi.pagePadding, 16),
                    sliver: SliverToBoxAdapter(
                      child: ProgressSummary(
                        state: state,
                        onFilterChanged: context.read<ProgressController>().setFilter,
                      ),
                    ),
                  ),
                  if (state.templates == null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppUi.pagePadding,
                        0,
                        AppUi.pagePadding,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '提示词模板还没加载，暂时不能记录生成。',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  if (state.visible.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.all(AppUi.pagePadding),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          '没有「${state.filter!.label}」的镜头',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppUi.pagePadding),
                      sliver: SliverList.separated(
                        itemCount: state.visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final progress = state.visible[index];
                          return ProgressShotTile(
                            key: ValueKey(progress.shotId),
                            progress: progress,
                            onRecord: state.templates == null
                                ? null
                                : () => _record(context, progress),
                            onOpen: (generation) => _open(context, generation),
                            onTogglePick: (generation) =>
                                context.read<ProgressController>().togglePick(generation.id),
                          );
                        },
                      ),
                    ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _record(BuildContext context, ShotProgress progress) async {
    final controller = context.read<ProgressController>();
    final input = await showDialog<RecordInput>(
      context: context,
      builder: (_) => RecordGenerationDialog(
        shotNumber: progress.shot.index + 1,
        prompts: controller.state.promptsFor(progress.shot),
      ),
    );
    if (input == null) return;
    await controller.record(progress.shotId, input.platform, note: input.note);
  }

  Future<void> _open(BuildContext context, Generation generation) async {
    final controller = context.read<ProgressController>();
    final action = await showDialog<GenerationAction>(
      context: context,
      builder: (_) => GenerationDetailDialog(generation: generation),
    );
    switch (action) {
      case null:
        return;
      case NoteSaved(:final note):
        await controller.updateNote(generation.id, note);
      case GenerationDeleted():
        await controller.delete(generation.id);
    }
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.view_kanban_outlined, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('还没有分镜', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('先回分镜页生成一份完整的分镜，\n再在这里记录每个镜头的生成进度。', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
