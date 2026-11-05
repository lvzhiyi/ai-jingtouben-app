import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/share/storyboard_json.dart';
import '../../../data/share/storyboard_share.dart';
import '../../../data/storyboard/shot_line_parser.dart';
import '../controller.dart';
import '../state.dart';

/// 导出 JSON 给 ai-tools 的 `studio import`。走和分享相同的通道：
/// 移动端调起系统面板（隔空投送、存到文件），Web 复制全文。不需要提示词模板。
class ExportButton extends StatefulWidget {
  const ExportButton({super.key, required this.share});

  final StoryboardShare share;

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _busy = false;

  bool _canExport(StoryboardState state) =>
      state.loaded && !state.phase.isActive && state.items.any((item) => item is ParsedShot);

  Future<void> _export() async {
    final state = context.read<StoryboardController>().state;
    if (_busy || !_canExport(state)) return;
    setState(() => _busy = true);
    try {
      final json = const StoryboardJson().build(
        title: state.title,
        story: state.story,
        shots: state.drafts,
        characters: state.characters,
        incomplete:
            state.phase != GenerationPhase.done || state.items.any((item) => item is BrokenShot),
      );
      final result = await widget.share.share(title: '${state.title}.json', text: json);
      if (mounted && result == ShareResult.copied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分镜 JSON 已复制')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导出失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocSelector<StoryboardController, StoryboardState, bool>(
    selector: _canExport,
    builder: (context, enabled) => IconButton(
      tooltip: '导出 JSON',
      onPressed: enabled && !_busy ? _export : null,
      icon: _busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.data_object_rounded),
    ),
  );
}
