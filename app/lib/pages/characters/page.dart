import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/character_repository.dart';
import 'controller.dart';
import 'view.dart';

/// 角色卡入口：外貌、服装写一次，生成分镜和拼接提示词时复用。
class CharactersPage extends StatelessWidget {
  const CharactersPage({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        CharactersController(projectId: projectId, repository: context.read<CharacterRepository>()),
    child: const CharactersView(),
  );
}
