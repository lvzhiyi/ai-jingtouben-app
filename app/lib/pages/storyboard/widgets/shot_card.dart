import 'package:flutter/material.dart';

import '../../../data/models/shot_draft.dart';

/// 一个镜头：序号、景别、画面、台词、出场角色和「为什么这样拍」。
class ShotCard extends StatelessWidget {
  const ShotCard({super.key, required this.shot});

  final ShotDraft shot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${shot.index + 1}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      shot.shotSize.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(shot.scene, style: theme.textTheme.bodyLarge),
            if (shot.dialogue.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '「${shot.dialogue}」',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.primary),
              ),
            ],
            if (shot.characters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('出场：${shot.characters.join('、')}', style: secondary),
            ],
            if (shot.reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('为什么这样拍', style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(shot.reason, style: secondary),
            ],
            for (final warning in shot.warnings)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  warning,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
