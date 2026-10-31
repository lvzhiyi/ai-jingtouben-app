import 'dart:convert';

import 'package:drift/drift.dart';

/// 把字符串列表存成 JSON 数组文本。镜头的角色 ID 数量很少，不值得单独建关联表。
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) => (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
