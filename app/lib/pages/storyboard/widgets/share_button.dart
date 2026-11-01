import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/share/storyboard_share.dart';
import '../../../data/share/storyboard_text.dart';
import '../../../data/storyboard/shot_line_parser.dart';
import '../controller.dart';
import '../state.dart';

/// 分享状态独立于生成流程；读取点击时的完整页面快照。
class ShareButton extends StatefulWidget {
  const ShareButton({super.key, required this.share});

  final StoryboardShare share;

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _busy = false;

  bool _canShare(StoryboardState state) =>
      state.loaded &&
      !state.phase.isActive &&
      state.templates != null &&
      state.items.any((item) => item is ParsedShot);

  Future<void> _share() async {
    final state = context.read<StoryboardController>().state;
    if (_busy || !_canShare(state)) return;
    setState(() => _busy = true);
    try {
      final text = const StoryboardText().build(
        title: state.title,
        shots: state.drafts,
        characters: state.characters,
        promptsFor: state.promptsFor,
        incomplete:
            state.phase != GenerationPhase.done || state.items.any((item) => item is BrokenShot),
      );
      final result = await widget.share.share(title: state.title, text: text);
      if (mounted && result == ShareResult.copied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分镜已复制')));
      }
    } catch (_) {
      // 原生错误不包含到提示里，避免将内容或平台内部信息展示／记录出来。
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => BlocSelector<StoryboardController, StoryboardState, bool>(
    selector: _canShare,
    builder: (context, enabled) => IconButton(
      tooltip: '分享分镜',
      onPressed: enabled && !_busy ? _share : null,
      icon: _busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.ios_share_rounded),
    ),
  );
}
