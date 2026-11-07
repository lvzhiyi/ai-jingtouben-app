import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/data/props/prop_draw_api.dart';
import 'package:jingtouben/net/api_exception.dart';

String _delta(String text) => 'event: delta\ndata: ${jsonEncode({'text': text})}\n\n';

const _box = '{"anchor":"ground","size":0.3,"shapes":[{"t":"circle","x":0.5,"y":0.5,"r":0.2}]}';

PropDrawApi _api(int status, String body, {void Function(http.BaseRequest)? onRequest}) =>
    PropDrawApi(
      client: MockClient.streaming((request, bodyStream) async {
        onRequest?.call(request);
        return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
      }),
      baseUrl: Uri.parse('http://localhost:3000/'),
      deviceId: () async => 'device-1',
    );

String _items(List<String> items) => '{"items":[${items.join(',')}]}';

String _item(String name) => _box.replaceFirst('{', '{"name":"$name",');

void main() {
  test('拼起增量后按名字返回绘图；漏画和不合格的为 null', () async {
    final text = '```json\n${_items([_item('猫'), _item('书').replaceFirst('0.3', '9')])}\n```';
    late http.Request sent;
    final body = [
      for (var i = 0; i < text.length; i += 7)
        _delta(text.substring(i, (i + 7).clamp(0, text.length))),
      'event: done\ndata: {}\n\n',
    ].join();

    final result = await _api(
      200,
      body,
      onRequest: (r) => sent = r as http.Request,
    ).draw(['猫', '书', '狗']);

    expect(sent.url.path, '/props/draw');
    expect(sent.headers['x-device-id'], 'device-1');
    expect(jsonDecode(sent.body), {
      'names': ['猫', '书', '狗'],
    });
    expect(result.keys, ['猫', '书', '狗']);
    expect(result['猫']!.name, '猫');
    expect(result['书'], isNull, reason: '大小超出范围');
    expect(result['狗'], isNull, reason: '模型漏画');
  });

  test('模型输出不是 JSON 或没有 items 时全部为 null', () {
    expect(PropDrawApi.parseDrawings('画不出来', ['猫']), {'猫': null});
    expect(PropDrawApi.parseDrawings('{"items":', ['猫']), {'猫': null});
    expect(PropDrawApi.parseDrawings('{"list":[]}', ['猫']), {'猫': null});
    expect(
      PropDrawApi.parseDrawings(_items([_item(' 猫 ')]), ['猫'])['猫'],
      isNotNull,
      reason: '名字归一化后对上',
    );
  });

  test('429 映射为限流，error 事件映射为服务错误，没有 done 视为中断', () async {
    await expectLater(
      _api(429, '').draw(['猫']),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.rateLimited)),
    );
    await expectLater(
      _api(200, 'event: error\ndata: {"code":"upstream_error"}\n\n').draw(['猫']),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'upstream_error')),
    );
    await expectLater(
      _api(200, _delta('{"items":')).draw(['猫']),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.interrupted)),
    );
  });

  test('连不上服务端映射为网络错误', () async {
    final api = PropDrawApi(
      client: MockClient((_) => throw const SocketLikeException()),
      baseUrl: Uri.parse('http://localhost:3000/'),
      deviceId: () async => 'device-1',
    );
    await expectLater(
      api.draw(['猫']),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network)),
    );
  });
}

class SocketLikeException implements Exception {
  const SocketLikeException();
}
