/// 把流式文本增量拼成完整的行。
///
/// 模型按「一行一个镜头 JSON」输出，但一行会被拆进多个增量，只有遇到换行才交出这一行。
class LineAccumulator {
  String _pending = '';

  /// 追加一段增量，返回其中已经完整的行（不含换行符）。
  List<String> add(String delta) {
    _pending += delta;
    final lines = _pending.split('\n');
    _pending = lines.removeLast();
    return [
      for (final line in lines) line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
    ];
  }

  /// 流结束时交出最后一行；模型输出的最后一行经常没有换行。
  List<String> flush() {
    final rest = _pending.trim();
    _pending = '';
    return rest.isEmpty ? const [] : [rest];
  }
}
