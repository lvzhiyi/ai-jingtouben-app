import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/db/converters.dart';
import 'package:jingtouben/data/models/shot_prop.dart';

void main() {
  test('道具名归一化：去空白、全角转半角、限长', () {
    expect(normalizePropName(' 咖啡 杯 '), '咖啡杯');
    expect(normalizePropName('ＵＳＢ　线'), 'USB线');
    expect(normalizePropName('一二三四五六七八九十'), '一二三四五六七八九十');
    expect(normalizePropName('一二三四五六七八九十一'), isNull);
    expect(normalizePropName('  '), isNull);
    expect(normalizePropName(3), isNull);
  });

  test('道具列表存成 JSON，读回时跳过坏项', () {
    const converter = ShotPropListConverter();
    const props = [ShotProp(name: '伞', owner: '林夏'), ShotProp(name: '猫')];
    expect(converter.fromSql(converter.toSql(props)), props);
    expect(
      converter.fromSql('[{"name":"猫","owner":""},{"owner":"林夏"},"伞",{"name":"书","owner":1}]'),
      const [ShotProp(name: '猫'), ShotProp(name: '书')],
    );
    expect(const ShotProp(name: '伞', owner: '林夏').withOwner('夏夏').owner, '夏夏');
  });
}
