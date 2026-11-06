import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../resources/theme.dart';
import '../controller.dart';
import '../state.dart';

/// 生成按钮和状态行：连接中、已收到几个镜头、首字延迟。
class GenerationBar extends StatelessWidget {
  const GenerationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoryboardController, StoryboardState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.canGenerate != current.canGenerate ||
          previous.firstTokenLatency != current.firstTokenLatency ||
          previous.items.length != current.items.length,
      builder: (context, state) {
        final controller = context.read<StoryboardController>();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppUi.pagePadding, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.phase.isActive)
                OutlinedButton.icon(
                  onPressed: () => controller.add(const GenerationCancelled()),
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                )
              else
                FilledButton.icon(
                  onPressed: state.canGenerate ? () => _generate(context) : null,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(state.items.isEmpty ? '生成分镜' : '重新生成'),
                ),
              const SizedBox(height: 10),
              Text(
                _status(state),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 已经在进度板上记过生成时，重新生成前先确认：新分镜会替换全部镜头，记录随之清空。
  static Future<void> _generate(BuildContext context) async {
    final controller = context.read<StoryboardController>();
    if (await controller.hasProgress()) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('重新生成分镜？'),
          content: const Text('新分镜会替换现在的全部镜头，进度板上的生成记录和选定结果会一起清空。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重新生成'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    controller.add(const GenerationRequested());
  }

  static String _status(StoryboardState state) {
    final count = state.items.length;
    final latency = state.firstTokenLatency;
    final latencyText = latency == null ? '' : ' · 首字 ${latency.inMilliseconds} ms';
    return switch (state.phase) {
      GenerationPhase.idle when state.canGenerate => '写好故事后点击生成',
      GenerationPhase.idle => '故事至少 ${StoryboardState.minStoryLength} 个字',
      GenerationPhase.connecting => '正在连接…',
      GenerationPhase.streaming => '生成中 · 已收到 $count 个镜头$latencyText',
      GenerationPhase.done => '共 $count 个镜头$latencyText',
      GenerationPhase.cancelled => '已停止，收到 $count 个镜头',
      GenerationPhase.failed => '生成失败：${state.error?.message ?? '未知错误'}',
    };
  }
}
