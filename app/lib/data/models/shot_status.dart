/// 镜头在进度板上的状态。
enum ShotStatus {
  pending('待生成'),
  generating('生成中'),
  picked('已选定');

  const ShotStatus(this.label);

  final String label;
}
