import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../net/api_exception.dart';
import '../models/prop_drawing.dart';
import '../models/shot_prop.dart';
import '../storyboard/sse_decoder.dart';

/// 调用转发服务的道具绘图接口：`POST props/draw`，响应为 SSE，协议和分镜接口相同。
///
/// 增量拼成完整文本后再解析：绘图 JSON 是一个整体对象，不像分镜那样能逐行展示。
class PropDrawApi {
  PropDrawApi({
    required this._client,
    required Uri baseUrl,
    required this._deviceId,
    this.connectTimeout = const Duration(seconds: 15),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _endpoint = baseUrl.resolve('props/draw');

  final http.Client _client;
  final Uri _endpoint;
  final Future<String> Function() _deviceId;
  final Duration connectTimeout;

  /// 两个事件之间的最长间隔，服务端每 15 秒发一次心跳。
  final Duration idleTimeout;

  /// 一次最多画几个。
  static const maxBatch = 5;

  /// 画一批道具。返回每个名字对应的绘图；模型漏画或校验不通过的为 null。
  /// 网络或服务端出错时抛 [ApiException]。
  Future<Map<String, PropDrawing?>> draw(List<String> names) async {
    assert(names.isNotEmpty && names.length <= maxBatch);
    final request = http.Request('POST', _endpoint)
      ..headers.addAll({
        'content-type': 'application/json',
        'accept': 'text/event-stream',
        'x-device-id': await _deviceId(),
      })
      ..body = jsonEncode({'names': names});

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(connectTimeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout);
    } catch (_) {
      throw const ApiException(ApiErrorKind.network);
    }
    if (response.statusCode != 200) {
      await response.stream.listen(null).cancel();
      throw ApiException(
        response.statusCode == 429 ? ApiErrorKind.rateLimited : ApiErrorKind.server,
        statusCode: response.statusCode,
      );
    }

    final text = StringBuffer();
    final events = response.stream
        .transform(utf8.decoder)
        .transform(const SseDecoder())
        .timeout(idleTimeout);
    try {
      await for (final event in events) {
        switch (event.event) {
          case 'delta':
            text.write(_field(event.data, 'text'));
          case 'error':
            throw ApiException(ApiErrorKind.server, code: _field(event.data, 'code'));
          case 'done':
            return parseDrawings(text.toString(), names);
        }
      }
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(ApiErrorKind.network);
    }
    throw const ApiException(ApiErrorKind.interrupted);
  }

  /// 从模型输出里取出 `{"items":[…]}`，逐个校验，按请求的名字对上号。
  /// 模型偶尔包一层代码块或多说一句话，取第一个 `{` 到最后一个 `}` 之间的部分。
  static Map<String, PropDrawing?> parseDrawings(String text, List<String> names) {
    final result = <String, PropDrawing?>{for (final name in names) name: null};
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return result;
    Object? json;
    try {
      json = jsonDecode(text.substring(start, end + 1));
    } on FormatException {
      return result;
    }
    final items = json is Map ? json['items'] : null;
    if (items is! List) return result;
    for (final item in items) {
      final drawing = PropDrawing.tryParse(item);
      if (drawing == null) continue;
      // 模型写回的名字可能和请求的写法略有出入，归一化后再对
      final name = names.firstWhere((n) => normalizePropName(n) == drawing.name, orElse: () => '');
      if (name.isNotEmpty && result[name] == null) result[name] = drawing;
    }
    return result;
  }

  static String _field(String data, String key) {
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
        final value = json[key];
        if (value is String) return value;
      }
    } on FormatException {
      // 忽略损坏的事件体
    }
    return '';
  }
}
