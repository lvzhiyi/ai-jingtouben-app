import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../resources/theme.dart';
import 'controller.dart';
import 'state.dart';
import 'widgets/create_project_dialog.dart';
import 'widgets/project_tile.dart';

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('镜头本')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text('新建短剧'),
      ),
      body: BlocBuilder<ProjectsController, ProjectsState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          if (state.projects.isEmpty) {
            return const Center(child: Text('还没有短剧，点右下角新建一个'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 8, AppUi.pagePadding, 96),
                itemCount: state.projects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => ProjectTile(project: state.projects[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final controller = context.read<ProjectsController>();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const CreateProjectDialog(),
    );
    if (title == null) return;
    final id = await controller.create(title);
    if (!context.mounted) return;
    await context.push('/projects/$id');
  }
}
