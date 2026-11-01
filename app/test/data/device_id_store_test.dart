import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/device/device_id_store.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('首次生成后持久化，并发读取和新实例拿到同一个 ID', () async {
    final store = DeviceIdStore(db);
    final ids = await Future.wait([store.read(), store.read()]);

    expect(ids[0], ids[1]);
    expect(ids[0], matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(await DeviceIdStore(db).read(), ids[0]);
  });

  test('读取失败后清掉缓存，同一个实例下次重新读取', () async {
    final flaky = _FlakyDatabase();
    final store = DeviceIdStore(flaky);

    await expectLater(store.read(), throwsStateError);
    expect(await store.read(), isNotEmpty);
    await flaky.close();
  });
}

/// 第一次读取失败，之后正常。
class _FlakyDatabase extends AppDatabase {
  _FlakyDatabase() : super(NativeDatabase.memory());

  var _failNext = true;

  @override
  Future<String?> readValue(String key) {
    if (_failNext) {
      _failNext = false;
      throw StateError('磁盘读取失败');
    }
    return super.readValue(key);
  }
}
