import 'package:http/http.dart' as http;

import 'http_client_io.dart' if (dart.library.js_interop) 'http_client_web.dart' as platform;

/// 创建支持边收边读的 HTTP 客户端。
///
/// 移动端用 dart:io 实现；Web 端默认的 BrowserClient 基于 XHR，要等响应全部结束才交出数据，
/// 流式就失效了，所以 Web 换成基于 fetch 的 FetchClient。
http.Client createStreamingClient() => platform.createClient();
