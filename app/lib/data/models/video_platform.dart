/// 支持导出提示词的视频平台。新增平台：加一个枚举值 + 服务端加一套模板。
enum VideoPlatform {
  jimeng('即梦'),
  kling('可灵');

  const VideoPlatform(this.label);

  final String label;

  static VideoPlatform? tryParse(Object? raw) {
    for (final platform in values) {
      if (platform.name == raw) return platform;
    }
    return null;
  }
}
