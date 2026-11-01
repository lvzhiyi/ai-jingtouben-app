import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/db/app_database.dart';
import '../../data/models/character_profile.dart';
import '../../data/repositories/character_repository.dart';
import '../../resources/theme.dart';
import 'controller.dart';
import 'state.dart';
import 'widgets/character_editor_dialog.dart';
import 'widgets/character_tile.dart';

class CharactersView extends StatelessWidget {
  const CharactersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CharactersController, CharactersState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('角色卡')),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: state.reachedLimit
            ? null
            : FloatingActionButton.extended(
                onPressed: state.loading ? null : () => _edit(context),
                icon: const Icon(Icons.person_add_alt_1, color: AppTheme.pink),
                label: const Text('新建角色'),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppUi.contentMaxWidth),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppUi.pagePadding, 8, AppUi.pagePadding, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '外貌和服装写一次，生成分镜时交给模型参考，每个镜头的提示词都会复用。'
                      '每部短剧最多 ${CharacterRepository.maxPerProject} 个角色。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (state.loading)
                  const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                else if (state.characters.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppUi.pagePadding),
                    sliver: SliverToBoxAdapter(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 42,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text('还没有角色', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Text(
                                '不建角色也能生成，模型会沿用故事里的称呼；\n建了角色，人物外貌在每个镜头里保持一致。',
                                textAlign: TextAlign.center,
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
                      itemCount: state.characters.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final character = state.characters[index];
                        return CharacterTile(
                          key: ValueKey(character.id),
                          character: character,
                          onEdit: () => _edit(context, character),
                          onDelete: () => _delete(context, character),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, [CharacterCard? character]) async {
    final controller = context.read<CharactersController>();
    final profile = await showDialog<CharacterProfile>(
      context: context,
      builder: (_) => CharacterEditorDialog(
        initial: character?.toProfile(),
        isNameTaken: (name) => controller.isNameTaken(name, exceptId: character?.id),
      ),
    );
    if (profile == null) return;
    await controller.save(profile, id: character?.id);
  }

  Future<void> _delete(BuildContext context, CharacterCard character) async {
    final controller = context.read<CharactersController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除「${character.name}」？'),
        content: const Text('已经生成的分镜不受影响，之后生成时不再参考这个角色。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(character.id);
  }
}
