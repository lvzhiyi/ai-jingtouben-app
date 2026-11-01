import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../resources/theme.dart';
import 'controller.dart';
import 'state.dart';
import 'widgets/create_project_dialog.dart';
import 'widgets/creation_hero.dart';
import 'widgets/project_tile.dart';

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_circle, color: AppTheme.pink),
        label: const Text('新建短剧'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
            child: BlocBuilder<ProjectsController, ProjectsState>(
              builder: (context, state) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(AppUi.pagePadding),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '镜头本',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '每一个灵感，都值得开拍',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          CreationHero(onCreate: () => _create(context)),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: Text('我的故事', style: theme.textTheme.titleLarge)),
                              if (!state.loading)
                                Text(
                                  '${state.projects.length} 个短剧',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.loading)
                    const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                  else if (state.projects.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppUi.pagePadding),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text('第一幕，等你落笔', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 8),
                                const Text('从一个人物、一次相遇或一个念头开始。', textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _create(context),
                                  child: const Text('创建我的第一个故事 →'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppUi.pagePadding),
                      sliver: SliverList.separated(
                        itemCount: state.projects.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) =>
                            ProjectTile(project: state.projects[index]),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 112)),
                ],
              ),
            ),
          ),
        ),
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
