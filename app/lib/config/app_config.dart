import 'package:flutter/foundation.dart';

/// 构建期配置，通过 `--dart-define` 传入。不从本地存储读取，避免一个包被改成指向别的后端。
class AppConfig {
  const AppConfig._(this.apiBaseUrl);

  /// 转发服务地址，始终以 `/` 结尾，便于用 [Uri.resolve] 拼接相对路径。
  final Uri apiBaseUrl;

  /// 没传 `API_BASE_URL` 时按平台选本机转发服务的地址。
  factory AppConfig.fromEnvironment() {
    const raw = String.fromEnvironment('API_BASE_URL');
    return AppConfig.parse(
      raw.isEmpty ? localServerUrl(defaultTargetPlatform, web: kIsWeb) : raw,
      release: kReleaseMode,
    );
  }

  /// 本机开发时的转发服务地址：Android 模拟器里 localhost 指向模拟器自己，电脑要用 10.0.2.2 访问。
  /// 真机调试仍需通过 `--dart-define` 传电脑的局域网 IP。
  static String localServerUrl(TargetPlatform platform, {required bool web}) =>
      !web && platform == TargetPlatform.android
      ? 'http://10.0.2.2:3000/'
      : 'http://localhost:3000/';

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
