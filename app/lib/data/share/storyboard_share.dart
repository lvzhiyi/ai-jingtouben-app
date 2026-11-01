import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'share_api.g.dart';

enum ShareResult { presented, copied }

/// 移动端使用类型安全的原生通道；Web 和其他平台复制全文。
class StoryboardShare {
  Future<ShareResult> share({required String title, required String text}) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await ShareHostApi().shareText(title, text);
      return ShareResult.presented;
    }
    await Clipboard.setData(ClipboardData(text: text));
    return ShareResult.copied;
  }
}
