import 'package:drift/drift.dart';

import '../models/shot_size.dart';
import '../models/shot_status.dart';
import '../models/video_platform.dart';
import 'converters.dart';

/// 业务表统一预留 remoteId 和 updatedAt：以后做云同步只加逻辑，不改表结构。
mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get remoteId => text().nullable()();
}

/// 一部短剧，其余三张表都挂在它下面。
class Projects extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get story => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 角色卡：外貌、服装写一次，所有镜头的提示词复用。
///
/// 类名不叫 Characters，避免和 Flutter 导出的 `Characters` 冲突。
@DataClassName('CharacterCard')
class CharacterCards extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 20)();
  TextColumn get appearance => text().withDefault(const Constant(''))();
  TextColumn get outfit => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 一个镜头。提示词不存在这里，使用时按「镜头 + 角色卡 + 平台模板」实时拼接。
@TableIndex(name: 'shots_project_order', columns: {#projectId, #sortOrder})
class Shots extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// 镜头顺序。`order` 是 SQL 关键字，所以叫 sort_order。
  IntColumn get sortOrder => integer()();
  TextColumn get shotSize => textEnum<ShotSize>()();
  TextColumn get scene => text()();
  TextColumn get dialogue => text().withDefault(const Constant(''))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get characterIds =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get status => textEnum<ShotStatus>().withDefault(Constant(ShotStatus.pending.name))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 一次「抽卡」：用户拿某个平台的提示词去生成了一次，并标记哪次被选中。
class Generations extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get shotId => text().references(Shots, #id, onDelete: KeyAction.cascade)();
  TextColumn get platform => textEnum<VideoPlatform>()();

  /// 当次实际使用的提示词快照，用于回看哪种写法效果好。
  TextColumn get prompt => text()();
  TextColumn get resultNote => text().withDefault(const Constant(''))();
  BoolColumn get picked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 应用级键值：安装 ID、提示词模板缓存等。代替 SharedPreferences，存储只有 drift 一处。
@DataClassName('KeyValueEntry')
class KeyValues extends Table {
  TextColumn get entryKey => text()();
  TextColumn get entryValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {entryKey};
}
