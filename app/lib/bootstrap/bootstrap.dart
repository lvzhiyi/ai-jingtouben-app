import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import 'app_dependencies.dart';

/// 初始化绑定、全局错误处理和应用依赖，然后展示应用。
///
/// 绑定初始化与 runApp 在同一个 Zone 内；依赖初始化失败时展示失败页，而不是停在白屏。
void bootstrap() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack);
      return true;
    };

    final AppDependencies dependencies;
    try {
      dependencies = await AppDependencies.initialize();
    } catch (error, stack) {
      _reportError(error, stack);
      runApp(const _StartupFailureApp());
      return;
    }
    runApp(JingtoubenApp(dependencies: dependencies));
  }, _reportError);
}

/// 第一版只在调试模式打印；以后接崩溃上报时只改这里。
void _reportError(Object error, StackTrace? stack) {
  if (kDebugMode) debugPrint('Unhandled error: $error\n$stack');
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: Text('应用初始化失败，请重新启动'))),
  );
}
