import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../models/camera_move.dart';
import '../models/shot_draft.dart';
import '../models/shot_duration.dart';
import '../models/shot_prop.dart';
import '../models/shot_size.dart';

/// 单行解析结果：成功的镜头、需要重新生成的坏行，或可以忽略的行。
sealed class ShotLineResult extends Equatable {
  const ShotLineResult();
}

final class ParsedShot extends ShotLineResult {
  const ParsedShot(this.shot, {this.repaired = false});

  final ShotDraft shot;

  /// 原始行不是合法 JSON，修复后才解析成功。统计「一次解析成功率」时，这类算失败。
  final bool repaired;

  @override
  List<Object?> get props => [shot, repaired];
}

final class BrokenShot extends ShotLineResult {
  const BrokenShot({required this.index, required this.raw, required this.reason});

  final int index;
  final String raw;
  final String reason;

  @override
  List<Object?> get props => [index, raw, reason];
}

/// 空行、代码块标记等不是镜头的内容。
final class SkippedLine extends ShotLineResult {
  const SkippedLine();

  @override
  List<Object?> get props => [];
}

/// 还没写完的一行解析出的半成品镜头，只用于生成过程中的展示，不校验、不落库。
final class PartialShot extends Equatable {
  const PartialShot({
    required this.index,
    this.shotSize,
    this.scene = '',
    this.dialogue = '',
    this.reason = '',
  });

  final int index;

  /// 景别字段写完整之前为 null。
  final ShotSize? shotSize;
  final String scene;
  final String dialogue;
  final String reason;

  @override
  List<Object?> get props => [index, shotSize, scene, dialogue, reason];
}

/// 把模型输出的一行文本解析成镜头。
///
/// 每行独立解析：坏一行只把这一行标成「需重新生成」，不影响其他镜头。
/// 顺序是：直接解析 → 修复常见格式错误后再解析 → 字段校验，缺字段用默认值并记录提示。
class ShotLineParser {
  const ShotLineParser();

  ShotLineResult parse(String line, {required int index}) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('```')) return const SkippedLine();

    var repaired = false;
    var decoded = _tryDecode(trimmed);
    if (decoded == null) {
      final fixed = repair(trimmed);
      if (fixed != trimmed) {
        decoded = _tryDecode(fixed);
        repaired = decoded != null;
      }
    }
    if (decoded == null) return BrokenShot(index: index, raw: trimmed, reason: 'JSON 格式错误');
    if (decoded is! Map<String, dynamic>) {
      return BrokenShot(index: index, raw: trimmed, reason: '不是镜头对象');
    }
    return _validate(decoded, index: index, raw: trimmed, repaired: repaired);
  }

  /// 解析还没写完的半行：借用 [repair] 补齐被截断的引号和括号，读出已经写出来的字段。
  ///
  /// 截在键名或冒号处时补齐后仍不是合法 JSON，返回 null，由调用方沿用上一次的结果。
  PartialShot? parsePartial(String line, {required int index}) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('```')) return null;
    final decoded = _tryDecode(repair(trimmed));
    if (decoded is! Map<String, dynamic>) return null;
    final shot = PartialShot(
      index: index,
      shotSize: ShotSize.tryParse(decoded['shotSize']),
      scene: _text(decoded['scene']),
      dialogue: _text(decoded['dialogue']),
      reason: _text(decoded['reason']),
    );
    return shot.shotSize == null && shot.scene.isEmpty ? null : shot;
  }

  /// 修复模型常见的格式错误：列表符号或编号前缀、行尾逗号、对象里多余的逗号、输出被截断没有闭合。
  static String repair(String input) {
    var text = input.replaceFirst(RegExp(r'^(?:[-*]\s+|\d+\s*[.)、]\s*)'), '');
    text = text.replaceFirst(RegExp(r',\s*$'), '');
    text = _closeTruncated(text);
    return text.replaceAllMapped(RegExp(r',\s*([}\]])'), (match) => match.group(1)!);
  }

  /// 补齐被截断的字符串引号和括号。
  static String _closeTruncated(String text) {
    final closers = <String>[];
    var inString = false;
    var escaped = false;
    for (final char in text.split('')) {
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      switch (char) {
        case '"':
          inString = true;
        case '{':
          closers.add('}');
        case '[':
          closers.add(']');
        case '}' || ']':
          if (closers.isNotEmpty) closers.removeLast();
      }
    }
    final buffer = StringBuffer(text);
    if (inString) buffer.write('"');
    for (final closer in closers.reversed) {
      buffer.write(closer);
    }
    return buffer.toString();
  }

  ShotLineResult _validate(
    Map<String, dynamic> json, {
    required int index,
    required String raw,
    required bool repaired,
  }) {
    final scene = _text(json['scene']);
    if (scene.isEmpty) return BrokenShot(index: index, raw: raw, reason: '缺少画面描述');

    final warnings = <String>[];
    var shotSize = ShotSize.tryParse(json['shotSize']);
    if (shotSize == null) {
      shotSize = ShotSize.medium;
      warnings.add('景别无法识别，已按中景处理');
    }
    final reason = _text(json['reason']);
    if (reason.isEmpty) warnings.add('缺少拍摄理由');
    var cameraMove = CameraMove.tryParse(json['cameraMove']);
    if (cameraMove == null) {
      cameraMove = CameraMove.fixed;
      warnings.add('运镜无法识别，已按固定处理');
    }
    final durationMs = _durationMs(json['durationSec']);
    if (json['durationSec'] != null && durationMs == null) warnings.add('时长无效，已按默认时长');
    final characters = switch (json['characters']) {
      final List<dynamic> list => [
        for (final name in list)
          if (name is String && name.trim().isNotEmpty) name.trim(),
      ],
      _ => const <String>[],
    };

    final props = _props(json['props'], characters: characters, warnings: warnings);

    return ParsedShot(
      ShotDraft(
        index: index,
        shotSize: shotSize,
        scene: scene,
        dialogue: _text(json['dialogue']),
        reason: reason,
        characters: characters,
        cameraMove: cameraMove,
        durationMs: durationMs,
        shotProps: props,
        warnings: warnings,
      ),
      repaired: repaired,
    );
  }

  /// 模型给的道具列表：名字归一化、去重，归属不是出场角色时置空，最多 [maxPropsPerShot] 个。
  /// 没给时返回 null（预演按关键词兜底）；不是数组或有格式不对的项时忽略这些项并提示。
  static List<ShotProp>? _props(
    Object? value, {
    required List<String> characters,
    required List<String> warnings,
  }) {
    if (value == null) return null;
    if (value is! List<dynamic>) {
      warnings.add('道具格式无效，已忽略');
      return null;
    }
    final props = <ShotProp>[];
    var invalid = false;
    for (final item in value) {
      final name = normalizePropName(item is Map ? item['name'] : null);
      if (name == null) {
        invalid = true;
        continue;
      }
      if (props.any((prop) => prop.name == name)) continue;
      final owner = item is Map ? item['owner'] : null;
      props.add(
        ShotProp(name: name, owner: owner is String && characters.contains(owner) ? owner : null),
      );
    }
    if (invalid) warnings.add('道具格式无效，已忽略');
    return props.take(maxPropsPerShot).toList();
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  /// 模型给的秒数换成毫秒；不是数字或超出 1–10 秒时返回 null，按默认规则推导。
  static int? _durationMs(Object? value) {
    if (value is! num || !value.isFinite) return null;
    final ms = (value * 1000).round();
    return ms < minShotDurationMs || ms > maxShotDurationMs ? null : ms;
  }

  static Object? _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}
