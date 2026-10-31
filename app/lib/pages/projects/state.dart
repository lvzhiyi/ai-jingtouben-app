import 'package:equatable/equatable.dart';

import '../../data/db/app_database.dart';

class ProjectsState extends Equatable {
  const ProjectsState({this.projects = const [], this.loading = true});

  final List<Project> projects;

  /// 数据库第一次推送之前为 true，用来区分「加载中」和「真的没有项目」。
  final bool loading;

  @override
  List<Object?> get props => [projects, loading];
}
