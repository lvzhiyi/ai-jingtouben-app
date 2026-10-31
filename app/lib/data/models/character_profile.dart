import 'package:equatable/equatable.dart';

/// 角色卡里参与分镜生成和提示词拼接的字段。
class CharacterProfile extends Equatable {
  const CharacterProfile({required this.name, this.appearance = '', this.outfit = ''});

  final String name;
  final String appearance;
  final String outfit;

  Map<String, String> toJson() => {'name': name, 'appearance': appearance, 'outfit': outfit};

  @override
  List<Object?> get props => [name, appearance, outfit];
}
