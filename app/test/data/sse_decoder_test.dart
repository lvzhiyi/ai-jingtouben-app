import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/storyboard/sse_decoder.dart';

Future<List<SseEvent>> _decode(List<String> chunks) =>
    Stream.fromIterable(chunks).transform(const SseDecoder()).toList();

void main() {
  test('一个事件被拆进多个网络包时，拼完整再分发', () async {
    final events = await _decode(['event: del', 'ta\ndata: {"te', 'xt":"a"}\n', '\n']);
    expect(events, [const SseEvent(event: 'delta', data: '{"text":"a"}')]);
  });

  test('\\r\\n 被拆开时不会多出空行', () async {
    final events = await _decode(['data: a\r', '\n\r\n', 'data: b\r\n\r\n']);
    expect(events.map((e) => e.data), ['a', 'b']);
  });

  test('多行 data 用换行拼接，注释行忽略', () async {
    final events = await _decode([': ping\n\ndata: line1\ndata: line2\n\n']);
    expect(events, [const SseEvent(data: 'line1\nline2')]);
  });

  test('流结束时没有空行收尾的事件被丢弃', () async {
    final events = await _decode(['data: complete\n\ndata: partial']);
    expect(events.map((e) => e.data), ['complete']);
  });
}
