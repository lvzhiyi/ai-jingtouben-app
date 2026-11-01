import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/video_platform.dart';

/// 镜头卡底部的视频提示词：切换平台查看，一键复制后去即梦 / 可灵粘贴。
///
/// 当前选中的平台是纯界面状态，由本组件自己保存。
class ShotPrompts extends StatefulWidget {
  const ShotPrompts({super.key, required this.prompts});

  final Map<VideoPlatform, String> prompts;

  @override
  State<ShotPrompts> createState() => _ShotPromptsState();
}

class _ShotPromptsState extends State<ShotPrompts> {
  late VideoPlatform _platform = widget.prompts.keys.first;

  Future<void> _copy(String prompt) async {
    await Clipboard.setData(ClipboardData(text: prompt));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已复制${_platform.label}提示词')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 模板刷新后平台可能变少，选中项不在了就回到第一个
    if (!widget.prompts.containsKey(_platform)) _platform = widget.prompts.keys.first;
    final prompt = widget.prompts[_platform]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('视频提示词', style: theme.textTheme.labelMedium),
            const Spacer(),
            SegmentedButton<VideoPlatform>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final platform in widget.prompts.keys)
                  ButtonSegment(value: platform, label: Text(platform.label)),
              ],
              selected: {_platform},
              onSelectionChanged: (selection) => setState(() => _platform = selection.single),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    prompt,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                  ),
                ),
                IconButton(
                  tooltip: '复制${_platform.label}提示词',
                  onPressed: () => _copy(prompt),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
