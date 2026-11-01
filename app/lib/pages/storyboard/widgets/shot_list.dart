import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/storyboard/shot_line_parser.dart';
import '../../../resources/theme.dart';
import '../controller.dart';
import '../state.dart';
import 'broken_shot_card.dart';
import 'shot_card.dart';

/// 镜头列表（Sliver）。只在镜头、角色卡或模板变化时重建；SliverList 懒加载，只构建可见的卡片。
class ShotList extends StatelessWidget {
  const ShotList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryboardController, StoryboardState>(
      buildWhen: (previous, current) =>
          previous.items != current.items ||
          previous.characters != current.characters ||
          previous.templates != current.templates,
      builder: (context, state) {
        final items = state.items;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 0, AppUi.pagePadding, 12),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => switch (items[index]) {
              ParsedShot(:final shot) => ShotCard(
                key: ValueKey('shot-${shot.index}'),
                shot: shot,
                prompts: state.promptsFor(shot),
              ),
              BrokenShot broken => BrokenShotCard(
                key: ValueKey('broken-${broken.index}'),
                shot: broken,
              ),
              SkippedLine() => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}
