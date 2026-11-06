import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/progress_repository.dart';
import 'generation_time.dart';

/// 详情对话框的结果。
sealed class GenerationAction {
  const GenerationAction();
}

final class NoteSaved extends GenerationAction {
  const NoteSaved(this.note);

  final String note;
}

final class GenerationDeleted extends GenerationAction {
  const GenerationDeleted();
}

/// 一次生成的详情：当时用的提示词快照（可复制，方便照着再抽一次）、修改备注、删除。
class GenerationDetailDialog extends StatefulWidget {
  const GenerationDetailDialog({super.key, required this.generation});

  final Generation generation;

  @override
  State<GenerationDetailDialog> createState() => _GenerationDetailDialogState();
}

class _GenerationDetailDialogState extends State<GenerationDetailDialog> {
  late final _note = TextEditingController(text: widget.generation.resultNote);
  bool _copied = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.generation.prompt));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generation = widget.generation;
    return AlertDialog(
      title: Text(
        '${generation.platform.label} · ${formatGenerationTime(generation.createdAt)}'
        '${generation.picked ? ' · 已选定' : ''}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当时的提示词', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  generation.prompt,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copy,
                icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                label: Text(_copied ? '已复制' : '复制提示词'),
              ),
            ),
            TextField(
              controller: _note,
              maxLength: ProgressRepository.maxNoteLength,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: '效果备注'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const GenerationDeleted()),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: const Text('删除记录'),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(NoteSaved(_note.text)),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
