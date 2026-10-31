import 'package:flutter/material.dart';

import '../../../data/storyboard/shot_line_parser.dart';

/// 解析失败的镜头：留在原位置，提示需要重新生成，并展示原始输出方便排查。
class BrokenShotCard extends StatelessWidget {
  const BrokenShotCard({super.key, required this.shot});

  final BrokenShot shot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${shot.index + 1} 需要重新生成（${shot.reason}）',
              style: theme.textTheme.titleSmall?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 6),
            Text(
              shot.raw,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
