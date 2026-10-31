import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/project_repository.dart';
import 'controller.dart';
import 'view.dart';

/// 短剧项目列表入口。
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProjectsController(context.read<ProjectRepository>()),
    child: const ProjectsView(),
  );
}
