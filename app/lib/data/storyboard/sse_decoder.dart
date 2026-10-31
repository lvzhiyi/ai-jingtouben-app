import 'dart:async';

import 'package:equatable/equatable.dart';

class SseEvent extends Equatable {
  const SseEvent({this.event = 'message', required this.data, this.id});

  final String event;
  final String data;
  final String? id;

  @override
  List<Object?> get props => [event, data, id];
}

/// 把已解码的文本流解析成 SSE 事件（按 WHATWG 规范的子集）。
///
/// 网络包边界和事件边界没有关系：一个事件可能被拆进好几个包，`\r\n` 也可能正好断在中间，
/// 所以要缓冲未完成的行，遇到空行才分发事件。多字节字符被拆开的问题由上游的 `utf8.decoder` 处理。
class SseDecoder extends StreamTransformerBase<String, SseEvent> {
  const SseDecoder();

  static const _lf = 0x0A;
  static const _cr = 0x0D;

  @override
  Stream<SseEvent> bind(Stream<String> stream) async* {
    final builder = _EventBuilder();
    var pending = '';
    await for (final chunk in stream) {
      pending += chunk;
      var lineStart = 0;
      var i = 0;
      while (i < pending.length) {
        final char = pending.codeUnitAt(i);
        if (char != _lf && char != _cr) {
          i++;
          continue;
        }
        // 末尾的 \r 可能是被拆开的 \r\n，等下一段数据到了再处理这一行。
        if (char == _cr && i + 1 == pending.length) break;
        final line = pending.substring(lineStart, i);
        i += (char == _cr && pending.codeUnitAt(i + 1) == _lf) ? 2 : 1;
        lineStart = i;
        final event = builder.feed(line);
        if (event != null) yield event;
      }
      pending = pending.substring(lineStart);
    }
    // 流结束时没有以空行收尾的事件按规范丢弃。
  }
}

class _EventBuilder {
  String _event = '';
  final _data = <String>[];
  String? _id;

  /// 输入一行（不含换行符）；遇到空行且有数据时返回完整事件。
  SseEvent? feed(String line) {
    if (line.isEmpty) {
      if (_data.isEmpty) {
        _event = '';
        return null;
      }
      final event = SseEvent(
        event: _event.isEmpty ? 'message' : _event,
        data: _data.join('\n'),
        id: _id,
      );
      _event = '';
      _data.clear();
      return event;
    }
    if (line.startsWith(':')) return null; // 注释，服务端用作心跳
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        _event = value;
      case 'data':
        _data.add(value);
      case 'id':
        _id = value;
    }
    return null;
  }
}
