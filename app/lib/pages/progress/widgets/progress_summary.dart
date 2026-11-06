import 'package:flutter/material.dart';

import '../../../data/models/shot_status.dart';
import '../state.dart';

/// 进度总览：已选定几个镜头、进度条，以及按状态筛选。
class ProgressSummary extends StatelessWidget {
  const ProgressSummary({super.key, required this.state, required this.onFilterChanged});

  final ProgressState state;
  final ValueChanged<ShotStatus?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final picked = state.count(ShotStatus.picked);
    final total = state.shots.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$picked / $total',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text('个镜头已选定', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.pickedRatio,
                minHeight: 8,
                semanticsLabel: '选定进度',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text('全部 $total'),
                  selected: state.filter == null,
                  onSelected: (_) => onFilterChanged(null),
                ),
                for (final status in ShotStatus.values)
                  ChoiceChip(
                    label: Text('${status.label} ${state.count(status)}'),
                    selected: state.filter == status,
                    // 再点一次已选中的筛选回到全部
                    onSelected: (selected) => onFilterChanged(selected ? status : null),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
