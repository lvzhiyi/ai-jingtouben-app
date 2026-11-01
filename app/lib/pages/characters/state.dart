import 'package:equatable/equatable.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/character_repository.dart';

class CharactersState extends Equatable {
  const CharactersState({this.characters = const [], this.loading = true});

  final List<CharacterCard> characters;

  /// 数据库第一次推送之前为 true，用来区分「加载中」和「还没有角色」。
  final bool loading;

  /// 达到上限时隐藏新建按钮；加载中按钮保留但不可点，避免数据到达时按钮突然弹出。
  bool get reachedLimit => characters.length >= CharacterRepository.maxPerProject;

  @override
  List<Object?> get props => [characters, loading];
}
