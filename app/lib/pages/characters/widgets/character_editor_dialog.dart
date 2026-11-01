import 'package:flutter/material.dart';

import '../../../data/models/character_profile.dart';

/// 新建或编辑角色卡；确认时返回填写的资料，取消时返回 null。
///
/// [isNameTaken] 由调用方提供，用于提示同一项目内重名。
class CharacterEditorDialog extends StatefulWidget {
  const CharacterEditorDialog({super.key, this.initial, required this.isNameTaken});

  final CharacterProfile? initial;
  final bool Function(String name) isNameTaken;

  @override
  State<CharacterEditorDialog> createState() => _CharacterEditorDialogState();
}

class _CharacterEditorDialogState extends State<CharacterEditorDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _appearance = TextEditingController(text: widget.initial?.appearance);
  late final _outfit = TextEditingController(text: widget.initial?.outfit);
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _appearance.dispose();
    _outfit.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final error = name.isEmpty
        ? '请填写角色名'
        : widget.isNameTaken(name)
        ? '已经有叫「$name」的角色了'
        : null;
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    Navigator.of(context).pop(
      CharacterProfile(
        name: name,
        appearance: _appearance.text.trim(),
        outfit: _outfit.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? '新建角色' : '编辑角色'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.initial == null,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: '角色名',
                hintText: '和故事里的称呼一致，例如：我、初恋',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _appearance,
              maxLength: 200,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '外貌',
                hintText: '年龄、发型、五官等，例如：二十出头，黑色齐肩短发',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _outfit,
              maxLength: 200,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '服装', hintText: '例如：米色风衣，白色帆布鞋'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
