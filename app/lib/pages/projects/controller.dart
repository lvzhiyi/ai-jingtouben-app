import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/project_repository.dart';
import 'state.dart';

/// 订阅项目列表；增删后由数据库推送新列表，不手动刷新。
class ProjectsController extends Cubit<ProjectsState> {
  ProjectsController(this._repository) : super(const ProjectsState()) {
    _subscription = _repository.watchAll().listen(
      (projects) => emit(ProjectsState(projects: projects, loading: false)),
    );
  }

  final ProjectRepository _repository;
  late final StreamSubscription<List<Project>> _subscription;

  /// 新建项目并返回 id；标题为空时使用默认名。
  Future<String> create(String title) {
    final trimmed = title.trim();
    return _repository.create(trimmed.isEmpty ? '未命名短剧' : trimmed);
  }

  Future<void> delete(String id) => _repository.delete(id);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
