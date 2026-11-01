import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/data/storyboard/shot_line_parser.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/net/api_exception.dart';

String _delta(String text) => 'event: delta\ndata: ${jsonEncode({'text': text})}\n\n';

/// 把响应体按固定字节数切块，故意把中文字符的 UTF-8 字节拆开。
List<List<int>> _chunks(String body, int size) {
  final bytes = utf8.encode(body);
  return [
    for (var i = 0; i < bytes.length; i += size) bytes.sublist(i, min(i + size, bytes.length)),
  ];
}

StoryboardApi _api(int status, List<List<int>> chunks) => StoryboardApi(
  client: MockClient.streaming((request, _) async {
    expect(request.headers['x-device-id'], 'device-1');
    return http.StreamedResponse(Stream.fromIterable(chunks), status);
  }),
  baseUrl: Uri.parse('http://localhost:3000/'),
  deviceId: () async => 'device-1',
);

void main() {
  const story = '雨夜，林夏在老街等一个不会来的人。';

  test('字节、事件、JSON 行三层被拆开时都能还原出完整镜头', () async {
    final body = [
      _delta('{"shotSize":"全景","scene":"雨夜老街'),
      _delta('","reason":"交代环境"}\n{"shotSize":"特写",'),
      _delta('"scene":"林夏回头"}'),
      ': ping\n\n',
      'event: done\ndata: {}\n\n',
    ].join();

    final updates = await _api(200, _chunks(body, 7)).generate(story: story).toList();

    expect(updates.first, isA<FirstTokenArrived>());
    final scenes = [
      for (final update in updates.whereType<ShotLineArrived>())
        (update.result as ParsedShot).shot.scene,
    ];
    expect(scenes, ['雨夜老街', '林夏回头']);
    expect(updates.last, isA<GenerationCompleted>());
  });

  test('429 映射为限流错误', () async {
    await expectLater(
      _api(429, const []).generate(story: story).toList(),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.rateLimited)),
    );
  });

  test('服务端 error 事件映射为服务错误', () async {
    final body = 'event: error\ndata: {"code":"upstream_error"}\n\n';
    await expectLater(
      _api(200, _chunks(body, 64)).generate(story: story).toList(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'upstream_error')),
    );
  });

  test('没收到 done 就断开时报告中断', () async {
    final body = _delta('{"shotSize":"全景","scene":"街口"}\n');
    await expectLater(
      _api(200, _chunks(body, 64)).generate(story: story).toList(),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.interrupted)),
    );
  });
  test('正在生成的一行按增量交出半成品，内容不变时不重复交出', () async {
    final body = [
      _delta('{"shotSize":"全景","sc'),
      _delta('ene":"雨夜'),
      _delta('老街"'),
      _delta(',"characters":["林'),
      _delta('夏"],"reason":"交代环境"}\n'),
      'event: done\ndata: {}\n\n',
    ].join();

    final updates = await _api(200, _chunks(body, 64)).generate(story: story).toList();

    final drafts = [for (final update in updates.whereType<ShotDrafting>()) update.shot.scene];
    expect(drafts, ['雨夜', '雨夜老街']);
    expect(updates.whereType<ShotLineArrived>(), hasLength(1));
  });
}
