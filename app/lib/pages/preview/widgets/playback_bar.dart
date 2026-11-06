import 'package:flutter/material.dart';

import '../../../data/models/shot_draft.dart';
import '../../../data/models/shot_duration.dart';

/// 按镜头分段的进度条：每段长度按镜头时长分配，点一段跳到那一镜。
class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.shots,
    required this.index,
    required this.progress,
    required this.onSeek,
  });

  final List<ShotDraft> shots;
  final int index;

  /// 当前镜头内进度，0–1。
  final double progress;
  final ValueChanged<int> onSeek;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < shots.length; i++)
          Expanded(
            flex: shots[i].effectiveDurationMs,
            child: Semantics(
              button: true,
              label: '跳到镜头 ${i + 1}',
              child: GestureDetector(
                key: ValueKey('preview-segment-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSeek(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: i < index ? 1 : (i == index ? progress : 0),
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
