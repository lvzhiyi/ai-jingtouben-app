import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/prop_drawing.dart';

Map<String, Object?> _valid({Map<String, Object?> extra = const {}}) => {
  'name': '吉他',
  'anchor': 'hand',
  'size': 0.6,
  'grip': [0.5, 0.2],
  'shapes': [
    {'t': 'ellipse', 'x': 0.5, 'y': 0.72, 'w': 0.55, 'h': 0.4, 'fill': 'light'},
    {
      't': 'polyline',
      'pts': [
        [0.5, 0.05],
        [0.5, 0.6],
        [0.52, 0.62],
      ],
    },
    {
      't': 'line',
      'pts': [
        [0.4, 0.1],
        [0.6, 0.1],
      ],
    },
    {
      't': 'polygon',
      'pts': [
        [0.4, 0.8],
        [0.6, 0.8],
        [0.5, 0.9],
      ],
      'fill': 'dark',
    },
    {'t': 'circle', 'x': 0.5, 'y': 0.7, 'r': 0.08, 'fill': 'accent'},
    {'t': 'arc', 'x': 0.5, 'y': 0.3, 'r': 0.1, 'start': 180, 'end': 360},
  ],
  ...extra,
};

PropDrawing? _parseWith(Map<String, Object?> patch) =>
    PropDrawing.tryParse({..._valid(), ...patch});

PropDrawing? _parseShape(Map<String, Object?> shape) => _parseWith({
  'shapes': [shape],
});

void main() {
  test('合法的绘图解析成功，圆转成宽高相等的椭圆，往返 JSON 不变', () {
    final drawing = PropDrawing.tryParse(_valid())!;
    expect(drawing.name, '吉他');
    expect(drawing.anchor, PropAnchor.hand);
    expect(drawing.grip, const Offset(0.5, 0.2));
    expect(drawing.shapes, hasLength(6));
    expect(
      drawing.shapes[4],
      const PropEllipse(center: Offset(0.5, 0.7), width: 0.16, height: 0.16, fill: PropFill.accent),
    );
    expect(PropDrawing.tryParse(drawing.toJson()), drawing);
  });

  test('名字归一化；名字、摆放位置、大小不合法时整个丢弃', () {
    expect(_parseWith({'name': ' 吉 他 '})!.name, '吉他');
    expect(_parseWith({'name': ''}), isNull);
    expect(_parseWith({'anchor': 'ceiling'}), isNull);
    expect(_parseWith({'size': 0.01}), isNull);
    expect(_parseWith({'size': 2}), isNull);
    expect(_parseWith({'size': '0.5'}), isNull);
    expect(PropDrawing.tryParse('不是对象'), isNull);
  });

  test('拿在手里的必须有握持点，其余位置不需要', () {
    expect(_parseWith({'grip': null}), isNull);
    expect(
      _parseWith({
        'grip': [0.5],
      }),
      isNull,
    );
    expect(
      _parseWith({
        'grip': [0.5, 2],
      }),
      isNull,
    );
    final ground = _parseWith({'anchor': 'ground', 'grip': null})!;
    expect(ground.grip, isNull);
    expect(ground.anchor, PropAnchor.ground);
  });

  test('图形数量 1–30 个', () {
    expect(_parseWith({'shapes': []}), isNull);
    expect(_parseWith({'shapes': 'x'}), isNull);
    final circle = {'t': 'circle', 'x': 0.5, 'y': 0.5, 'r': 0.1};
    expect(_parseWith({'shapes': List.filled(30, circle)}), isNotNull);
    expect(_parseWith({'shapes': List.filled(31, circle)}), isNull);
  });

  test('图形类型和填充只认白名单', () {
    expect(_parseShape({'t': 'path', 'd': 'M0 0'}), isNull);
    expect(_parseShape({'t': 'circle', 'x': 0.5, 'y': 0.5, 'r': 0.1, 'fill': '#ff0000'}), isNull);
    expect(
      _parseShape({'t': 'circle', 'x': 0.5, 'y': 0.5, 'r': 0.1}),
      isNotNull,
      reason: '没给填充按 none',
    );
    expect(
      _parseWith({
        'shapes': ['circle'],
      }),
      isNull,
    );
  });

  test('点数：线段 2 个，折线 2–16 个，多边形 3–12 个', () {
    List<List<double>> pts(int n) => [
      for (var i = 0; i < n; i++) [i / 20, 0.5],
    ];
    expect(_parseShape({'t': 'line', 'pts': pts(2)}), isNotNull);
    expect(_parseShape({'t': 'line', 'pts': pts(3)}), isNull);
    expect(_parseShape({'t': 'polyline', 'pts': pts(16)}), isNotNull);
    expect(_parseShape({'t': 'polyline', 'pts': pts(17)}), isNull);
    expect(_parseShape({'t': 'polyline', 'pts': pts(1)}), isNull);
    expect(_parseShape({'t': 'polygon', 'pts': pts(2)}), isNull);
    expect(_parseShape({'t': 'polygon', 'pts': pts(12)}), isNotNull);
    expect(_parseShape({'t': 'polygon', 'pts': pts(13)}), isNull);
    expect(_parseShape({'t': 'line', 'pts': 'x'}), isNull);
  });

  test('坐标允许略超出方框，超过 −0.05–1.05 丢弃；半径、宽高必须为正', () {
    expect(_parseShape({'t': 'circle', 'x': 1.04, 'y': -0.04, 'r': 0.1}), isNotNull);
    expect(_parseShape({'t': 'circle', 'x': 1.2, 'y': 0.5, 'r': 0.1}), isNull);
    expect(_parseShape({'t': 'circle', 'x': 0.5, 'y': 0.5, 'r': 0}), isNull);
    expect(_parseShape({'t': 'ellipse', 'x': 0.5, 'y': 0.5, 'w': 0.2, 'h': -0.1}), isNull);
    expect(_parseShape({'t': 'ellipse', 'x': 0.5, 'y': 0.5, 'w': 0.2}), isNull);
    expect(
      _parseShape({
        't': 'line',
        'pts': [
          [0, 0],
          [0.5, 1.5],
        ],
      }),
      isNull,
    );
    expect(
      _parseShape({'t': 'arc', 'x': 0.5, 'y': 0.5, 'r': 0.1, 'start': 0, 'end': 9999}),
      isNull,
    );
    expect(_parseShape({'t': 'arc', 'x': 0.5, 'y': 0.5, 'r': 0.1, 'start': 0}), isNull);
  });

  test('内置道具不生成', () {
    expect(isBuiltinProp('伞'), isTrue);
    expect(isBuiltinProp('黑伞'), isTrue);
    expect(isBuiltinProp('手机'), isTrue);
    expect(isBuiltinProp('吉他'), isFalse);
  });
}
