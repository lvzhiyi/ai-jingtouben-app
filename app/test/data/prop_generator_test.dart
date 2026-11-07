import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/models/prop_drawing_status.dart';
import 'package:jingtouben/data/props/prop_draw_api.dart';
import 'package:jingtouben/data/props/prop_generator.dart';
import 'package:jingtouben/data/repositories/prop_repository.dart';

/// 假的绘图服务：记录每次请求的名字；[fail] 里的名字不画，[status] 不是 200 时整批失败。
class _FakeServer {
  final requests = <List<String>>[];
  final fail = <String>{};
  int status = 200;
  int active = 0;
  int maxActive = 0;
  Completer<void>? gate;

  http.Client get client => MockClient((request) async {
    final names = (jsonDecode(request.body)['names'] as List).cast<String>();
    requests.add(names);
    active++;
    maxActive = active > maxActive ? active : maxActive;
    await (gate?.future ?? Future<void>.delayed(Duration.zero));
    active--;
    if (status != 200) return http.Response('', status);
    final items = [
      for (final name in names)
        if (!fail.contains(name))
          {
            'name': name,
            'anchor': 'ground',
            'size': 0.3,
            'shapes': [
              {'t': 'circle', 'x': 0.5, 'y': 0.5, 'r': 0.2},
            ],
          },
    ];
    final text = jsonEncode({'items': items});
    return http.Response(
      'event: delta\ndata: ${jsonEncode({'text': text})}\n\nevent: done\ndata: {}\n\n',
      200,
      headers: {'content-type': 'text/event-stream; charset=utf-8'},
    );
  });
}

void main() {
  late AppDatabase db;
  late PropRepository repository;
  late _FakeServer server;
  var now = DateTime(2026, 11, 7, 10);

  PropGenerator generator() => PropGenerator(
    api: PropDrawApi(
      client: server.client,
      baseUrl: Uri.parse('http://localhost:3000/'),
      deviceId: () async => 'd',
    ),
    repository: repository,
    now: () => now,
  );

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    repository = PropRepository(db);
    server = _FakeServer();
    now = DateTime(2026, 11, 7, 10);
  });

  tearDown(() => db.close());

  test('没画过的道具请求生成并缓存；内置道具和已缓存的不请求', () async {
    final props = generator();
    expect(await props.ensure(['猫', '伞', '手机', '猫', '吉他']), ['猫', '吉他']);
    expect(server.requests, [
      ['猫', '吉他'],
    ]);
    final records = await repository.load(['猫', '吉他']);
    expect(records['猫']!.status, PropDrawingStatus.ready);
    expect(records['猫']!.drawing!.name, '猫');

    expect(await props.ensure(['吉他', '猫']), isEmpty);
    expect(server.requests, hasLength(1));
  });

  test('每批最多 5 个，最多 2 批同时进行，一次最多 10 个', () async {
    final names = [for (var i = 0; i < 13; i++) '道具$i'];
    final props = generator();
    expect(await props.ensure(names), names.take(10));
    expect(server.requests.map((r) => r.length), [5, 5]);
    expect(server.maxActive, 2);
    // 剩下的下次打开预演时再生成
    expect(await props.ensure(names), names.skip(10));
  });

  test('漏画、校验不过、服务端出错都记为失败；当天不自动重试，第二天重试', () async {
    server.fail.add('书');
    final props = generator();
    await props.ensure(['猫', '书']);
    expect((await repository.load(['书']))['书']!.status, PropDrawingStatus.failed);

    server.status = 429;
    await props.ensure(['狗']);
    expect((await repository.load(['狗']))['狗']!.status, PropDrawingStatus.failed);

    server.status = 200;
    expect(await props.ensure(['书', '狗']), isEmpty);
    now = now.add(const Duration(days: 1));
    expect(await props.ensure(['书', '狗']), ['书', '狗']);
    expect((await repository.load(['狗']))['狗']!.status, PropDrawingStatus.ready);
  });

  test('同一道具正在请求时不重复请求；重画删缓存后重新生成，不受当天失败限制', () async {
    server.gate = Completer<void>();
    final props = generator();
    final first = props.ensure(['猫']);
    await Future<void>.delayed(Duration.zero);
    expect(props.inFlight, {'猫'});
    expect(await props.ensure(['猫']), isEmpty);
    server.gate!.complete();
    await first;
    expect(props.inFlight, isEmpty);
    server.gate = null;

    server.fail.add('猫');
    await props.redraw('猫');
    expect(server.requests, hasLength(2));
    expect((await repository.load(['猫']))['猫']!.status, PropDrawingStatus.failed);
    await props.redraw('伞');
    expect(server.requests, hasLength(2), reason: '内置道具不重画');
  });

  test('缓存里的 JSON 损坏时按失败读出', () async {
    await db
        .into(db.propDrawings)
        .insert(
          PropDrawingsCompanion.insert(
            name: '坏的',
            drawingJson: const Value('{不是 JSON'),
            status: PropDrawingStatus.ready,
          ),
        );
    final record = (await repository.load(['坏的']))['坏的']!;
    expect(record.status, PropDrawingStatus.failed);
    expect(record.drawing, isNull);
    expect(await repository.load(const []), isEmpty);
    expect(await repository.watch(const []).first, isEmpty);
  });
}
