import 'package:flutter/material.dart';

/// 创作入口；装饰元素不依赖图片或网络资源。
class CreationHero extends StatelessWidget {
  const CreationHero({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF433B32), Color(0xFF553144)]
              : const [Color(0xFFFFF8D9), Color(0xFFFFDCE6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -45,
            child: ExcludeSemantics(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: .38), width: 30),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('灵感，从这里开场', style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 28),
                Text('让故事，\n有画面。', style: theme.textTheme.headlineLarge?.copyWith(fontSize: 38)),
                const SizedBox(height: 14),
                Text('写下一个故事，\n把脑海里的想象变成一幕幕分镜。', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('开始新故事'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
