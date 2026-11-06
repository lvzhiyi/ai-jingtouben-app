import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/prompt/template_repository.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/progress_repository.dart';
import 'controller.dart';
import 'view.dart';

/// 镜头进度板入口：每个镜头去即梦 / 可灵生成了几次、哪一次选定，整部短剧还差多少。
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProgressController(
      projectId: projectId,
      progress: context.read<ProgressRepository>(),
      characters: context.read<CharacterRepository>(),
      templates: context.read<TemplateRepository>(),
    ),
    child: const ProgressView(),
  );
}
