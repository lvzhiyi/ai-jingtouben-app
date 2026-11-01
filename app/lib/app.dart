import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap/app_dependencies.dart';
import 'resources/theme.dart';
import 'router/app_router.dart';

class JingtoubenApp extends StatefulWidget {
  const JingtoubenApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<JingtoubenApp> createState() => _JingtoubenAppState();
}

class _JingtoubenAppState extends State<JingtoubenApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    unawaited(widget.dependencies.close());
    super.dispose();
  }

  /// 把仓库按类型注入组件树，页面用 `context.read<T>()` 读取，测试时可以替换。
  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dependencies.projects),
        RepositoryProvider.value(value: dependencies.shots),
        RepositoryProvider.value(value: dependencies.storyboard),
        RepositoryProvider.value(value: dependencies.templates),
      ],
      child: MaterialApp.router(
        title: '镜头本',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
