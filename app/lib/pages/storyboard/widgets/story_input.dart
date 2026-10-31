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
        labelText: '故事',
        hintText: '用几句话写清楚：谁、在哪里、发生了什么、结局如何',
        alignLabelWithHint: true,
      ),
    );
  }
}
