import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/app.dart';
import 'package:jingtouben/bootstrap/app_dependencies.dart';
import 'package:jingtouben/data/db/app_database.dart';

import 'helpers/test_env.dart';

void main() {
  late AppDependencies dependencies;
  var clientClosed = false;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    clientClosed = false;
    dependencies = await AppDependencies.initialize(
      database: AppDatabase(NativeDatabase.memory()),
      httpClient: _TrackingClient(onClose: () => clientClosed = true),
    );
  });

  testWidgets('组装依赖后启动到项目列表，卸载时关闭网络客户端', (tester) async {
    await tester.pumpWidget(JingtoubenApp(dependencies: dependencies));
    await pumpUntilFound(tester, find.text('第一幕，等你落笔'));
    expect(find.text('镜头本'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(clientClosed, isTrue);
  });

  test('打开数据库失败时释放网络客户端并抛出', () async {
    await dependencies.close();
    clientClosed = false;
    // 目录不存在，SQLite 打不开文件
    final broken = AppDatabase(NativeDatabase(File('/nonexistent/jingtouben/test.db')));

    await expectLater(
      AppDependencies.initialize(
        database: broken,
        httpClient: _TrackingClient(onClose: () => clientClosed = true),
      ),
      throwsA(anything),
    );
    expect(clientClosed, isTrue);
  });
}

class _TrackingClient extends MockClient {
  _TrackingClient({required this.onClose}) : super((_) async => http.Response('', 503));

  final VoidCallback onClose;

  @override
  void close() {
    onClose();
    super.close();
  }
}
