import 'dart:async';
import 'dart:math' as math;

import '../../net/api_exception.dart';
import '../models/prop_drawing.dart';
import '../models/prop_drawing_status.dart';
import '../repositories/prop_repository.dart';
import 'prop_draw_api.dart';

/// 道具生成调度：查缓存，没画过的分批请求，结果写回缓存。页面监听缓存拿结果，不等这里返回。
///
/// - 内置道具（伞、手机）不生成；已生成的不重复生成；当天失败过的不自动重试。
/// - 一次最多为 [maxPerRequest] 个新道具请求生成，其余保持占位（需求 Q5）。
/// - 每批 [PropDrawApi.maxBatch] 个，最多 [maxParallel] 批同时进行。
/// - 正在请求的道具记在内存里，同一道具不会同时请求两次。
class PropGenerator {
  PropGenerator({
    required this._api,
    required this._repository,
    this.maxPerRequest = 10,
    this.maxParallel = 2,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final PropDrawApi _api;
  final PropRepository _repository;
  final int maxPerRequest;
  final int maxParallel;
  final DateTime Function() _now;
  final _inFlight = <String>{};

  /// 正在请求的道具名，页面据此区分「生成中」和「还没轮到」。
  Set<String> get inFlight => Set.unmodifiable(_inFlight);

  /// 确保这些道具（按出现顺序）都生成过。返回实际请求生成的道具名。
  Future<List<String>> ensure(List<String> names) async {
    final records = await _repository.load(names);
    final today = _now();
    final candidates = <String>[];
    for (final name in names) {
      if (candidates.contains(name) || isBuiltinProp(name) || _inFlight.contains(name)) continue;
      final record = records[name];
      if (record?.status == PropDrawingStatus.ready) continue;
      if (record != null && _sameDay(record.updatedAt, today)) continue;
      candidates.add(name);
      if (candidates.length == maxPerRequest) break;
    }
    await _generate(candidates);
    return candidates;
  }

  /// 重画：删掉缓存，单独请求一次，不受当天失败和数量上限限制。
  Future<void> redraw(String name) async {
    if (isBuiltinProp(name) || _inFlight.contains(name)) return;
    await _repository.clear(name);
    await _generate([name]);
  }

  Future<void> _generate(List<String> names) async {
    if (names.isEmpty) return;
    _inFlight.addAll(names);
    final batches = [
      for (var i = 0; i < names.length; i += PropDrawApi.maxBatch)
        names.sublist(i, math.min(i + PropDrawApi.maxBatch, names.length)),
    ];
    try {
      for (var i = 0; i < batches.length; i += maxParallel) {
        await Future.wait(batches.skip(i).take(maxParallel).map(_drawBatch));
      }
    } finally {
      _inFlight.removeAll(names);
    }
  }

  Future<void> _drawBatch(List<String> names) async {
    Map<String, PropDrawing?> drawings;
    try {
      drawings = await _api.draw(names);
    } on ApiException {
      drawings = {};
    }
    for (final name in names) {
      final drawing = drawings[name];
      if (drawing != null) {
        await _repository.saveReady(drawing);
      } else {
        await _repository.saveFailed(name);
      }
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
