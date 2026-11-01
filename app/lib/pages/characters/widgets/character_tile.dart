import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';

/// 一张角色卡：名字、外貌、服装。点击编辑，右侧按钮删除。
class CharacterTile extends StatelessWidget {
  const CharacterTile({
    super.key,
    required this.character,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterCard character;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  character.name.characters.first,
                  style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(character.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      character.appearance.isEmpty ? '外貌未填写' : character.appearance,
                      style: secondary,
                    ),
                    if (character.outfit.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('穿着：${character.outfit}', style: secondary),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
