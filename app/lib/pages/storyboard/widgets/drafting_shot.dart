import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/storyboard/shot_line_parser.dart';
import '../../../resources/theme.dart';
import '../controller.dart';
import '../state.dart';

/// 正在生成的镜头（Sliver），跟在镜头列表后面，字段写出多少就显示多少。
///
/// 每个增量都会更新它，所以单独订阅 `drafting`：高频重建只发生在这张卡片上，已完成的镜头列表不动。
class DraftingShot extends StatelessWidget {
  const DraftingShot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryboardController, StoryboardState>(
      buildWhen: (previous, current) => previous.drafting != current.drafting,
      builder: (context, state) {
        final shot = state.drafting;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 0, AppUi.pagePadding, 32),
          sliver: SliverToBoxAdapter(
            child: shot == null ? const SizedBox.shrink() : _DraftingShotCard(shot: shot),
          ),
        );
      },
    );
  }
}

class _DraftingShotCard extends StatelessWidget {
  const _DraftingShotCard({required this.shot});

  final PartialShot shot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      key: const ValueKey('drafting-shot'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${shot.index + 1}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text('正在写…', style: secondary),
                const Spacer(),
                if (shot.shotSize case final size?)
                  Text(size.label, style: theme.textTheme.labelMedium),
              ],
            ),
            if (shot.scene.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(shot.scene, style: theme.textTheme.bodyLarge),
            ],
            if (shot.dialogue.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '「${shot.dialogue}」',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.primary),
              ),
            ],
            if (shot.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(shot.reason, style: secondary),
            ],
          ],
        ),
      ),
    );
  }
}
