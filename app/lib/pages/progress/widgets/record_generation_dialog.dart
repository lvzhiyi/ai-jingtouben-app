import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/video_platform.dart';
import '../../../data/repositories/progress_repository.dart';

/// 记录对话框的结果：用了哪个平台、效果怎么样。提示词快照由控制器在确认时拼出。
class RecordInput {
  const RecordInput({required this.platform, this.note = ''});

  final VideoPlatform platform;
  final String note;
}

/// 记一次生成：选平台、复制这次要用的提示词，回来写一句效果。
class RecordGenerationDialog extends StatefulWidget {
  const RecordGenerationDialog({super.key, required this.shotNumber, required this.prompts});

  final int shotNumber;

  /// 各平台按当前角色卡拼好的提示词，不能为空。
  final Map<VideoPlatform, String> prompts;

  @override
  State<RecordGenerationDialog> createState() => _RecordGenerationDialogState();
}

class _RecordGenerationDialogState extends State<RecordGenerationDialog> {
  late VideoPlatform _platform = widget.prompts.keys.first;
  final _note = TextEditingController();
  bool _copied = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.prompts[_platform]!));
    // 对话框盖住了页面的 SnackBar，直接在按钮上反馈
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('镜头 #${widget.shotNumber} · 记一次生成'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<VideoPlatform>(
              showSelectedIcon: false,
              segments: [
                for (final platform in widget.prompts.keys)
                  ButtonSegment(value: platform, label: Text(platform.label)),
              ],
              selected: {_platform},
              onSelectionChanged: (selection) => setState(() {
                _platform = selection.single;
                _copied = false;
              }),
            ),
            const SizedBox(height: 12),
            Text('这次使用的提示词（会存一份快照）', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  widget.prompts[_platform]!,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copy,
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                label: Text(_copied ? '已复制' : '复制${_platform.label}提示词'),
              ),
            ),
            TextField(
              controller: _note,
              maxLength: ProgressRepository.maxNoteLength,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: '效果备注（可选）', hintText: '比如：表情对了，手部有点糊'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(RecordInput(platform: _platform, note: _note.text)),
          child: const Text('记下'),
        ),
      ],
    );
  }
}
