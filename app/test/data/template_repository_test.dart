import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/prompt/template_repository.dart';

String _set(int version) =>
    '{"version": $version, "templates": [{"platform": "jimeng", "version": 1, "shot": "{scene}", "character": "{name}"}]}';

void main() {
  late AppDatabase db;
  var remote = http.Response('', 503);
  var bundled = _set(1);
  var remoteCalls = 0;

  TemplateRepository build() => TemplateRepository(
    client: MockClient((request) async {
      remoteCalls++;
      expect(request.url.toString(), 'http://localhost:3000/templates');
      return remote;
    }),
    baseUrl: Uri.parse('http://localhost:3000/'),
    database: db,
    loadBundled: () async => bundled,
  );

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    remote = http.Response('', 503);
    bundled = _set(1);
    remoteCalls = 0;
  });

  tearDown(() => db.close());

  test('服务端可用时用服务端模板并写入缓存，同一实例只请求一次', () async {
    remote = http.Response.bytes(_set(3).codeUnits, 200);
    final repository = build();

    expect((await repository.load()).version, 3);
    expect((await repository.load()).version, 3);
    expect(remoteCalls, 1);

    // 断网后新建的实例读缓存
    remote = http.Response('', 503);
    expect((await build().load()).version, 3);
  });

  test('服务端返回坏数据时不写缓存，退回内置模板', () async {
    remote = http.Response('{"oops":', 200);
    expect((await build().load()).version, 1);
    expect(await db.readValue('prompt_templates'), isNull);
  });

  test('refresh 时重新请求服务端', () async {
    final repository = build();
    expect((await repository.load()).version, 1);

    remote = http.Response.bytes(_set(2).codeUnits, 200);
    expect((await repository.load(refresh: true)).version, 2);
  });

  test('内置模板损坏时抛错', () async {
    bundled = '{}';
    await expectLater(build().load(), throwsStateError);
  });
}
