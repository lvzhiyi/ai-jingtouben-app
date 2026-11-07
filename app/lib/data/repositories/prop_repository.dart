import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';

import '../db/app_database.dart';
import '../models/prop_drawing.dart';
import '../models/prop_drawing_status.dart';

/// 一个道具的缓存记录。没有记录表示还没生成过。
class PropRecord extends Equatable {
  const PropRecord({required this.status, required this.updatedAt, this.drawing});

  final PropDrawingStatus status;

  /// [status] 为 ready 时有值。
  final PropDrawing? drawing;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [status, drawing, updatedAt];
}

/// 道具绘图缓存：按道具名存，所有剧本共用，不随项目删除。
class PropRepository {
  PropRepository(this._db);

  final AppDatabase _db;

  /// 监听这些道具的记录；没有记录的道具不在结果里。
  Stream<Map<String, PropRecord>> watch(Iterable<String> names) {
    final list = names.toSet().toList();
    if (list.isEmpty) return Stream.value(const {});
    return (_db.select(_db.propDrawings)..where((t) => t.name.isIn(list))).watch().map(_toRecords);
  }

  Future<Map<String, PropRecord>> load(Iterable<String> names) async {
    final list = names.toSet().toList();
    if (list.isEmpty) return const {};
    return _toRecords(await (_db.select(_db.propDrawings)..where((t) => t.name.isIn(list))).get());
  }

  Future<void> saveReady(PropDrawing drawing) => _db
      .into(_db.propDrawings)
      .insertOnConflictUpdate(
        PropDrawingsCompanion.insert(
          name: drawing.name,
          drawingJson: Value(jsonEncode(drawing.toJson())),
          status: PropDrawingStatus.ready,
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> saveFailed(String name) => _db
      .into(_db.propDrawings)
      .insertOnConflictUpdate(
        PropDrawingsCompanion.insert(
          name: name,
          drawingJson: const Value(null),
          status: PropDrawingStatus.failed,
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// 删除缓存（重画前）。
  Future<void> clear(String name) =>
      (_db.delete(_db.propDrawings)..where((t) => t.name.equals(name))).go();

  static Map<String, PropRecord> _toRecords(List<PropDrawingRow> rows) => {
    for (final row in rows) row.name: _toRecord(row),
  };

  /// 读回时再校验一次：存储的 JSON 损坏（或以后收紧校验规则）时按失败处理，可以重画。
  static PropRecord _toRecord(PropDrawingRow row) {
    PropDrawing? drawing;
    if (row.status == PropDrawingStatus.ready && row.drawingJson != null) {
      try {
        drawing = PropDrawing.tryParse(jsonDecode(row.drawingJson!));
      } on FormatException {
        drawing = null;
      }
    }
    return PropRecord(
      status: drawing == null ? PropDrawingStatus.failed : PropDrawingStatus.ready,
      drawing: drawing,
      updatedAt: row.updatedAt,
    );
  }
}
