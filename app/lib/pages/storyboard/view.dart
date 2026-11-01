import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../resources/theme.dart';
import 'controller.dart';
import 'state.dart';
import 'widgets/drafting_shot.dart';
import 'widgets/generation_bar.dart';
import 'widgets/shot_list.dart';
import 'widgets/story_input.dart';

class StoryboardView extends StatelessWidget {
  const StoryboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StoryboardController, StoryboardState>(
      listenWhen: (previous, current) => current.error != null && previous.error != current.error,
      listener: (context, state) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!.message))),
      // 外层只关心加载和标题；生成过程中的高频更新由下面各自的 BlocBuilder 局部处理。
      buildWhen: (previous, current) =>
          previous.loaded != current.loaded || previous.title != current.title,
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(state.title.isEmpty ? '分镜' : state.title),
          actions: [
            IconButton(
              tooltip: '角色卡',
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => context.push(
                '/projects/${context.read<StoryboardController>().projectId}/characters',
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '故事 · 分镜工作台',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
        body: state.loaded
            ? _StoryboardBody(initialStory: state.story)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StoryboardBody extends StatelessWidget {
  const _StoryboardBody({required this.initialStory});

  final String initialStory;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StoryboardController>();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 12, AppUi.pagePadding, 0),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text('故事的起点', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('先写故事，再让每一幕有迹可循。', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 18),
                        StoryInput(
                          initialStory: initialStory,
                          onChanged: (story) => controller.add(StoryChanged(story)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: GenerationBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 12, AppUi.pagePadding, 16),
              sliver: SliverToBoxAdapter(
                child: Text('分镜手记', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            const ShotList(),
            const DraftingShot(),
          ],
        ),
      ),
    );
  }
}
