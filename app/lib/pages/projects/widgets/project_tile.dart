import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/app_database.dart';

class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final story = project.story.trim();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(project.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          story.isEmpty ? '还没有写故事' : story.replaceAll('\n', ' '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/projects/${project.id}'),
      ),
    );
  }
}
