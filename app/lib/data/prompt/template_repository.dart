import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../db/app_database.dart';
import 'prompt_template.dart';

/// 提示词模板的读取顺序：服务端最新 → 本地缓存 → 安装包内置。
///
/// 平台写法变化时只改服务端配置，不用发版；断网时用上次缓存，首次离线用内置的同一份文件。
class TemplateRepository {
  TemplateRepository({
    required http.Client client,
    required Uri baseUrl,
    required AppDatabase database,
    Future<String> Function()? loadBundled,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client,
       _endpoint = baseUrl.resolve('templates'),
       _database = database,
       _loadBundled = loadBundled ?? (() => rootBundle.loadString(_bundledAsset));

  static const _bundledAsset = 'assets/prompt_templates.json';
  static const _cacheKey = 'prompt_templates';

  final http.Client _client;
  final Uri _endpoint;
  final AppDatabase _database;
  final Future<String> Function() _loadBundled;
  final Duration timeout;
  PromptTemplateSet? _memory;

  Future<PromptTemplateSet> load({bool refresh = false}) async {
    final memory = _memory;
    if (memory != null && !refresh) return memory;
    final result = await _loadRemote() ?? await _loadCached() ?? await _loadBundledSet();
    _memory = result;
    return result;
  }

  Future<PromptTemplateSet?> _loadRemote() async {
    try {
      final response = await _client.get(_endpoint).timeout(timeout);
      if (response.statusCode != 200) return null;
      final body = utf8.decode(response.bodyBytes);
      final set = _parse(body);
      if (set != null) await _database.writeValue(_cacheKey, body);
      return set;
    } catch (_) {
      return null;
    }
  }

  Future<PromptTemplateSet?> _loadCached() async {
    final raw = await _database.readValue(_cacheKey);
    return raw == null ? null : _parse(raw);
  }

  Future<PromptTemplateSet> _loadBundledSet() async {
    final set = _parse(await _loadBundled());
    if (set == null) throw StateError('内置提示词模板损坏');
    return set;
  }

  static PromptTemplateSet? _parse(String raw) {
    try {
      return PromptTemplateSet.tryParse(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }
}
