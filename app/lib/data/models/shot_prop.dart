import 'package:equatable/equatable.dart';

/// 镜头里的一个道具：名字，以及拿在谁手里 / 在谁身边。来自模型输出的 `props` 字段。
class ShotProp extends Equatable {
  const ShotProp({required this.name, this.owner});

  /// 归一化后的道具名，见 [normalizePropName]。
  final String name;

  /// 出场角色名；为空表示放在场景里。
  final String? owner;

  /// 改归属（角色改名时用）。
  ShotProp withOwner(String? owner) => ShotProp(name: name, owner: owner);

  Map<String, Object?> toJson() => {'name': name, 'owner': owner};

  /// 从存储的 JSON 读回；格式不对返回 null。
  static ShotProp? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final owner = json['owner'];
    if (name is! String || name.isEmpty) return null;
    return ShotProp(name: name, owner: owner is String && owner.isNotEmpty ? owner : null);
  }

  @override
  List<Object?> get props => [name, owner];
}

/// 每个镜头最多几个道具。
const maxPropsPerShot = 3;

/// 道具名最多几个字。
const maxPropNameLength = 10;

/// 道具名归一化：全角字母数字转半角、去掉所有空白；空的或超过 [maxPropNameLength] 个字返回 null。
///
/// 道具缓存按名字查，同一个道具写法统一后，换剧本也能命中。
String? normalizePropName(Object? raw) {
  if (raw is! String) return null;
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    if (rune == 0x3000) continue; // 全角空格
    // 全角 ！ 到 ～ 对应半角 ! 到 ~
    final half = rune >= 0xFF01 && rune <= 0xFF5E ? rune - 0xFEE0 : rune;
    buffer.writeCharCode(half);
  }
  final name = buffer.toString().replaceAll(RegExp(r'\s+'), '');
  if (name.isEmpty || name.runes.length > maxPropNameLength) return null;
  return name;
}
