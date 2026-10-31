import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

class ProjectRepository {
  ProjectRepository(this._db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final AppDatabase _db;
  final Uuid _uuid;

  /// 按最近修改排序；数据变化时自动推送新列表。
  Stream<List<Project>> watchAll() =>
      (_db.select(_db.projects)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<Project?> find(String id) =>
      (_db.select(_db.projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 新建项目并返回 id。
  Future<String> create(String title) async {
    final id = _uuid.v4();
    await _db.into(_db.projects).insert(ProjectsCompanion.insert(id: id, title: title));
    return id;
  }

  Future<void> updateStory(String id, String story) =>
      (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(story: Value(story), updatedAt: Value(DateTime.now())),
      );

  /// 删除项目，角色卡、镜头和生成记录由外键级联删除。
  Future<void> delete(String id) =>
      (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
}
