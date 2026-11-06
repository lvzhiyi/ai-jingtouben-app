/// 运镜。模型输出必须落在这个枚举里；[label] 同时是展示文案和提示词里的写法。
///
/// 与服务端 `CAMERA_MOVES` 保持一致。存库用枚举名，改名要写迁移。
enum CameraMove {
  fixed('固定'),
  push('推'),
  pull('拉'),
  pan('摇'),
  track('移'),
  follow('跟'),
  crane('升降');

  const CameraMove(this.label);

  final String label;

  /// 按中文名或枚举名匹配，容忍「推镜头」「固定镜头」这类结尾；无法识别时返回 null，由调用方兜底。
  static CameraMove? tryParse(Object? raw) {
    if (raw is! String) return null;
    var value = raw.trim();
    if (value.endsWith('镜头')) value = value.substring(0, value.length - 2);
    for (final move in values) {
      if (move.label == value || move.name == value) return move;
    }
    return null;
  }
}
