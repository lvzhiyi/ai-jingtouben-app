import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/data/share/share_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/com/lvzhiyi/jingtouben/ShareApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.lvzhiyi.jingtouben'),
    swiftOut: 'ios/Runner/ShareApi.g.swift',
    dartPackageName: 'jingtouben',
  ),
)
@HostApi()
abstract class ShareHostApi {
  /// 只表示系统面板已展示，不表示用户已发送给其他应用。
  @asyncCallback
  void shareText(String title, String text);
}
