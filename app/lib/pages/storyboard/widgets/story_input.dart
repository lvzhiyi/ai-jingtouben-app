import 'package:flutter/material.dart';

/// 故事输入框。输入控制器由本组件创建和释放，内容变化通过 [onChanged] 交给控制器。
class StoryInput extends StatefulWidget {
  const StoryInput({super.key, required this.initialStory, required this.onChanged});

  final String initialStory;
  final ValueChanged<String> onChanged;

  @override
  State<StoryInput> createState() => _StoryInputState();
}

class _StoryInputState extends State<StoryInput> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialStory);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 4,
      maxLines: 10,
      maxLength: 3000,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        hintStyle: TextStyle(fontSize: 14, height: 1.7),
        hintText: '故事发生在哪里？谁走进了画面？\n写下人物、冲突和结局，让灵感慢慢展开……',
        alignLabelWithHint: true,
      ),
    );
  }
}
