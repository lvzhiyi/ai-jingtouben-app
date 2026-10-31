import 'package:flutter/foundation.dart';

/// 构建期配置，通过 `--dart-define` 传入。不从本地存储读取，避免一个包被改成指向别的后端。
class AppConfig {
  const AppConfig._(this.apiBaseUrl);

  /// 转发服务地址，始终以 `/` 结尾，便于用 [Uri.resolve] 拼接相对路径。
  final Uri apiBaseUrl;

  static const _defaultBaseUrl = 'http://localhost:3000/';

  factory AppConfig.fromEnvironment() => AppConfig.parse(
    const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl),
    release: kReleaseMode,
  );

  /// 校验地址；release 包必须用 https。错误信息不回显地址，防止误带的凭据进入日志。
  factory AppConfig.parse(String raw, {bool release = false}) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (release && uri.scheme != 'https')) {
      throw const FormatException('Invalid API_BASE_URL');
    }
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return AppConfig._(uri.replace(path: path));
  }
}
