import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/shot_prop.dart';

/// 把字符串列表存成 JSON 数组文本。镜头的出场角色数量很少，不值得单独建关联表。
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// 镜头的道具列表存成 JSON 数组文本；读回时跳过格式不对的项。
class ShotPropListConverter extends TypeConverter<List<ShotProp>, String> {
  const ShotPropListConverter();

  @override
  List<ShotProp> fromSql(String fromDb) => [
    for (final item in jsonDecode(fromDb) as List<dynamic>) ?ShotProp.fromJson(item),
  ];

  @override
  String toSql(List<ShotProp> value) => jsonEncode([for (final prop in value) prop.toJson()]);
}
