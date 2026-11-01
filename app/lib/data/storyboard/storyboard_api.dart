import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

import '../../net/api_exception.dart';
import '../models/character_profile.dart';
import 'line_accumulator.dart';
import 'shot_line_parser.dart';
import 'sse_decoder.dart';

/// 一次分镜生成过程中交给页面的更新。
sealed class GenerationUpdate extends Equatable {
  const GenerationUpdate();

  @override
  List<Object?> get props => [];
}

/// 收到第一段文本。[latency] 是从发出请求到首字的耗时，即「首字延迟」。
final class FirstTokenArrived extends GenerationUpdate {
  const FirstTokenArrived(this.latency);

  final Duration latency;

  @override
  List<Object?> get props => [latency];
}

/// 解析完一行：成功的镜头，或需要重新生成的坏行。
final class ShotLineArrived extends GenerationUpdate {
  const ShotLineArrived(this.result);

  final ShotLineResult result;

  @override
  List<Object?> get props => [result];
}

/// 正在生成的那一行有了新内容：已经写出来的字段，用于增量渲染。
/// 内容和上一次相同时不会重复发出。
final class ShotDrafting extends GenerationUpdate {
  const ShotDrafting(this.shot);

  final PartialShot shot;

  @override
  List<Object?> get props => [shot];
}

final class GenerationCompleted extends GenerationUpdate {
  const GenerationCompleted();
}

/// 调用转发服务的流式分镜接口：`POST storyboard/stream`，响应为 SSE。
///
/// 解析分三层，每层只解决一种「被拆开」：
/// 1. `utf8.decoder`：一个中文字符的 3 个字节被拆进两个网络包；
/// 2. [SseDecoder]：一个 SSE 事件被拆进多个网络包；
/// 3. [LineAccumulator]：一行镜头 JSON 被拆进多个 delta 事件。
///
/// 取消订阅返回的 Stream 即断开连接，服务端随之中止上游模型请求。
class StoryboardApi {
  StoryboardApi({
    required this._client,
    required Uri baseUrl,
    required this._deviceId,
    this._parser = const ShotLineParser(),
    this.connectTimeout = const Duration(seconds: 15),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _endpoint = baseUrl.resolve('storyboard/stream');

  final http.Client _client;
  final Uri _endpoint;
  final Future<String> Function() _deviceId;
  final ShotLineParser _parser;

  /// 发出请求到收到响应头的上限。
  final Duration connectTimeout;

  /// 两个事件之间的最长间隔。服务端每 15 秒发一次心跳，超过这个时间视为连接已卡死。
  final Duration idleTimeout;

  Stream<GenerationUpdate> generate({
    required String story,
    List<CharacterProfile> characters = const [],
  }) async* {
    final stopwatch = Stopwatch()..start();
    final request = http.Request('POST', _endpoint)
      ..headers.addAll({
        'content-type': 'application/json',
        'accept': 'text/event-stream',
        'x-device-id': await _deviceId(),
      })
      ..body = jsonEncode({
        'story': story,
        'characters': [for (final character in characters) character.toJson()],
      });

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

    final lines = LineAccumulator();
    var index = 0;
    var receivedText = false;
    PartialShot? drafting;

    ShotLineArrived? toUpdate(String line) {
      final result = _parser.parse(line, index: index);
      if (result is SkippedLine) return null;
      index++;
      return ShotLineArrived(result);
    }

    final events = response.stream
        .transform(utf8.decoder)
        .transform(const SseDecoder())
        .timeout(idleTimeout);
    try {
      await for (final event in events) {
        switch (event.event) {
          case 'delta':
            final text = _field(event.data, 'text');
            if (text.isNotEmpty) {
              if (!receivedText) {
                receivedText = true;
                yield FirstTokenArrived(stopwatch.elapsed);
              }
              for (final line in lines.add(text)) {
                final update = toUpdate(line);
                if (update != null) {
                  drafting = null;
                  yield update;
                }
              }
              final partial = _parser.parsePartial(lines.pending, index: index);
              if (partial != null && partial != drafting) {
                drafting = partial;
                yield ShotDrafting(partial);
              }
            }
          case 'error':
            throw ApiException(ApiErrorKind.server, code: _field(event.data, 'code'));
          case 'done':
            for (final line in lines.flush()) {
              final update = toUpdate(line);
              if (update != null) yield update;
            }
            yield const GenerationCompleted();
            return;
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

  /// 读取事件体里的字符串字段；事件体损坏时当作空内容。
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
