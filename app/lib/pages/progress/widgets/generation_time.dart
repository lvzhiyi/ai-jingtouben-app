/// 生成记录的时间，按本地时区显示成「11/6 14:05」。只有一处用到，不为它引入 intl。
String formatGenerationTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.month}/${local.day} ${two(local.hour)}:${two(local.minute)}';
}
