import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/prompt/template_repository.dart';
import '../../data/repositories/character_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/shot_repository.dart';
import '../../data/storyboard/storyboard_api.dart';
import 'controller.dart';
import 'view.dart';

/// 分镜页入口：写故事、流式生成分镜。
class StoryboardPage extends StatelessWidget {
  const StoryboardPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => StoryboardController(
      projectId: projectId,
      projects: context.read<ProjectRepository>(),
      shots: context.read<ShotRepository>(),
      characters: context.read<CharacterRepository>(),
      templates: context.read<TemplateRepository>(),
      api: context.read<StoryboardApi>(),
    )..add(const StoryboardOpened()),
    child: const StoryboardView(),
  );
}
