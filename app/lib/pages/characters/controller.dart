import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/db/app_database.dart';
import '../../data/models/character_profile.dart';
import '../../data/repositories/character_repository.dart';
import 'state.dart';

/// 订阅项目下的角色卡；增删改后由数据库推送新列表，不手动刷新。
class CharactersController extends Cubit<CharactersState> {
  CharactersController({required this.projectId, required this._repository})
    : super(const CharactersState()) {
    _subscription = _repository
        .watchByProject(projectId)
        .listen((characters) => emit(CharactersState(characters: characters, loading: false)));
  }

  final String projectId;
  final CharacterRepository _repository;
  late final StreamSubscription<List<CharacterCard>> _subscription;

  /// 角色名是镜头和角色卡的匹配依据，同一项目内不能重名。[exceptId] 是正在编辑的角色。
  bool isNameTaken(String name, {String? exceptId}) =>
      state.characters.any((card) => card.name == name.trim() && card.id != exceptId);

  /// [id] 为空时新建，否则更新。
  Future<void> save(CharacterProfile profile, {String? id}) =>
      id == null ? _repository.create(projectId, profile) : _repository.update(id, profile);

  Future<void> delete(String id) => _repository.delete(id);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
