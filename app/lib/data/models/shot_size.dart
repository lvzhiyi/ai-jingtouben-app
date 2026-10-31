/// 景别。模型输出必须落在这个枚举里；[label] 同时是展示文案和提示词里的写法。
///
/// 与服务端 `SHOT_SIZES` 保持一致。
enum ShotSize {
  extremeLong('大远景'),
  long('远景'),
  full('全景'),
  medium('中景'),
  mediumCloseUp('近景'),
  closeUp('特写'),
  extremeCloseUp('大特写');

  const ShotSize(this.label);

  final String label;

  /// 按中文名或枚举名匹配；无法识别时返回 null，由调用方决定兜底值。
  static ShotSize? tryParse(Object? raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    for (final size in values) {
      if (size.label == value || size.name == value) return size;
    }
    return null;
  }
}
