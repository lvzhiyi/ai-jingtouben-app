import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';
import '../../../data/models/shot_status.dart';
import '../../../data/repositories/progress_repository.dart';
import 'generation_time.dart';

/// 进度板上的一个镜头：序号、景别、状态、画面摘要，以及每一次生成记录。
class ProgressShotTile extends StatelessWidget {
  const ProgressShotTile({
    super.key,
    required this.progress,
    required this.onRecord,
    required this.onOpen,
    required this.onTogglePick,
  });

  final ShotProgress progress;

  /// 为 null 时不能记录（模板未加载）。
  final VoidCallback? onRecord;
  final ValueChanged<Generation> onOpen;
  final ValueChanged<Generation> onTogglePick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shot = progress.shot;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Text(
                    '#${shot.index + 1}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    shot.shotSize.label,
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  _StatusBadge(status: progress.status),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                shot.scene,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (progress.generations.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final (index, generation) in progress.generations.indexed)
                _GenerationRow(
                  number: index + 1,
                  generation: generation,
                  onOpen: () => onOpen(generation),
                  onTogglePick: () => onTogglePick(generation),
                ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.add_rounded),
                label: Text(progress.generations.isEmpty ? '记一次生成' : '再抽一次'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态标签，三种状态用不同底色区分。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ShotStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (status) {
      ShotStatus.pending => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      ShotStatus.generating => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      ShotStatus.picked => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
      ),
    );
  }
}

class _GenerationRow extends StatelessWidget {
  const _GenerationRow({
    required this.number,
    required this.generation,
    required this.onOpen,
    required this.onTogglePick,
  });

  final int number;
  final Generation generation;
  final VoidCallback onOpen;
  final VoidCallback onTogglePick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = generation.resultNote;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第 $number 次 · ${generation.platform.label} · '
                    '${formatGenerationTime(generation.createdAt)}',
                    style: theme.textTheme.labelMedium,
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: generation.picked ? '取消选定第 $number 次' : '选定第 $number 次',
              isSelected: generation.picked,
              onPressed: onTogglePick,
              icon: const Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
