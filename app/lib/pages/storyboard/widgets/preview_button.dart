import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../controller.dart';
import '../state.dart';

/// 顶栏「预演」：只在生成完成、有镜头时可用，见 [StoryboardState.canPreview]。
class PreviewButton extends StatelessWidget {
  const PreviewButton({super.key});

  @override
  Widget build(BuildContext context) => BlocSelector<StoryboardController, StoryboardState, bool>(
    selector: (state) => state.canPreview,
    builder: (context, canPreview) => IconButton(
      tooltip: canPreview ? '镜头预演' : '生成完成后可预演',
      icon: const Icon(Icons.slideshow_outlined),
      onPressed: canPreview
          ? () =>
                context.push('/projects/${context.read<StoryboardController>().projectId}/preview')
          : null,
    ),
  );
}
