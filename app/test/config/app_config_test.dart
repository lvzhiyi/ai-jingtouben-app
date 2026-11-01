import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/config/app_config.dart';

void main() {
  test('Android 模拟器默认用 10.0.2.2 访问电脑上的转发服务', () {
    expect(AppConfig.localServerUrl(TargetPlatform.android, web: false), 'http://10.0.2.2:3000/');
  });

  test('iOS 模拟器和 Web（包括 Android 上的浏览器）默认用 localhost', () {
    expect(AppConfig.localServerUrl(TargetPlatform.iOS, web: false), 'http://localhost:3000/');
    expect(AppConfig.localServerUrl(TargetPlatform.android, web: true), 'http://localhost:3000/');
  });

  test('地址补齐结尾的斜杠，release 包拒绝 http', () {
    expect(
      AppConfig.parse('http://192.168.1.8:3000').apiBaseUrl.toString(),
      'http://192.168.1.8:3000/',
    );
    expect(() => AppConfig.parse('http://localhost:3000/', release: true), throwsFormatException);
  });
}
