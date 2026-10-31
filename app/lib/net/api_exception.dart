/// 稳定的错误分类。不携带请求体、URL 或服务端原文，避免泄露到界面和日志。
enum ApiErrorKind {
  /// 网络不可达或连接异常。
  network,

  /// 连接或空闲超时。
  timeout,

  /// 被转发服务限流（HTTP 429）。
  rateLimited,

  /// 转发服务或上游模型返回错误。
  server,

  /// 流在收到结束事件前断开。
  interrupted;

  /// 面向用户的提示文案。
  String get message => switch (this) {
    ApiErrorKind.network => '网络连接失败，请检查网络后重试',
    ApiErrorKind.timeout => '服务响应超时，请稍后重试',
    ApiErrorKind.rateLimited => '请求太频繁，请稍等一分钟再试',
    ApiErrorKind.server => '生成服务暂时不可用，请稍后重试',
    ApiErrorKind.interrupted => '生成中断，可以重新生成',
  };
}

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.code});

  final ApiErrorKind kind;
  final int? statusCode;

  /// 服务端 error 事件里的错误码，例如 `upstream_error`。
  final String? code;

  @override
  String toString() => 'ApiException(${kind.name}, status: $statusCode, code: $code)';
}
