import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/prop_drawing.dart';
import 'package:jingtouben/data/models/shot_prop.dart';
import 'package:jingtouben/pages/preview/figure_pose.dart';
import 'package:jingtouben/pages/preview/prop_layout.dart';

PropDrawing _drawing(String name, PropAnchor anchor, {double size = 0.3}) => PropDrawing(
  name: name,
  anchor: anchor,
  size: size,
  grip: anchor == PropAnchor.hand ? const Offset(0.5, 0.2) : null,
  shapes: const [PropEllipse(center: Offset(0.5, 0.5), width: 0.4, height: 0.4)],
);

void main() {
  group('planProps', () {
    test('内置道具只给归属的人；没有归属给第一个人；黑伞和手机可以同时有', () {
      final plan = planProps(
        const [
          ShotProp(name: '黑伞', owner: '陈默'),
          ShotProp(name: '手机', owner: '陈默'),
          ShotProp(name: '伞'),
          ShotProp(name: '伞', owner: '路人'),
        ],
        figures: ['林夏', '陈默'],
        drawings: const {},
      );
      expect(
        plan.builtin['陈默'],
        const FigureProps(umbrella: true, darkUmbrella: true, phone: true),
      );
      expect(plan.builtin['林夏'], const FigureProps(umbrella: true));
      expect(plan.builtin.keys, unorderedEquals(['林夏', '陈默']));
    });

    test('手持道具先右手后左手；手被伞、手机或挥手占用时放脚边', () {
      final drawings = {
        for (final name in ['吉他', '书', '花束']) name: _drawing(name, PropAnchor.hand),
      };
      final free = planProps(
        const [
          ShotProp(name: '吉他', owner: '林夏'),
          ShotProp(name: '书', owner: '林夏'),
          ShotProp(name: '花束', owner: '林夏'),
        ],
        figures: ['林夏'],
        drawings: drawings,
      );
      expect(free.held['林夏'], (left: '书', right: '吉他'));
      expect(free.beside['林夏'], ['花束']);

      final busy = planProps(
        const [
          ShotProp(name: '伞', owner: '林夏'),
          ShotProp(name: '手机', owner: '林夏'),
          ShotProp(name: '吉他', owner: '林夏'),
        ],
        figures: ['林夏'],
        drawings: drawings,
      );
      expect(busy.held['林夏'], isNull);
      expect(busy.beside['林夏'], ['吉他']);

      final waving = planProps(
        const [ShotProp(name: '吉他', owner: '林夏')],
        figures: ['林夏'],
        drawings: drawings,
        rightHandBusy: true,
      );
      expect(waving.held['林夏'], (left: '吉他', right: null));
    });

    test('还没画好的、放地上 / 桌上 / 墙上的都放脚边；没有归属的放场景；归属不在画面里的不画', () {
      final plan = planProps(
        const [
          ShotProp(name: '行李箱', owner: '林夏'),
          ShotProp(name: '咖啡杯', owner: '林夏'),
          ShotProp(name: '挂钟', owner: '林夏'),
          ShotProp(name: '猫'),
          ShotProp(name: '吉他', owner: '陈默'),
        ],
        figures: ['林夏'],
        drawings: {'咖啡杯': _drawing('咖啡杯', PropAnchor.table), '挂钟': _drawing('挂钟', PropAnchor.wall)},
      );
      expect(plan.beside['林夏'], ['行李箱', '咖啡杯', '挂钟']);
      expect(plan.scene, ['猫']);
      expect(plan.held, isEmpty);
    });
  });

  test('手持道具的握持点对准手', () {
    final drawing = _drawing('吉他', PropAnchor.hand, size: 0.5);
    final rect = heldPropRect(drawing, hand: const Offset(100, 200), figureHeight: 400);
    expect(rect.size, const Size(200, 200));
    // 握持点 (0.5, 0.2) 落在手上
    expect(rect.topLeft + const Offset(100, 40), const Offset(100, 200));
  });

  test('脚边的道具底边贴脚底，右左交替，越往后越远', () {
    Rect at(int slot) =>
        besidePropRect(0.25, centerX: 200, feetY: 500, figureHeight: 400, slot: slot);
    expect(at(0).bottom, 500);
    expect(at(0).center.dx, greaterThan(200));
    expect(at(1).center.dx, lessThan(200));
    expect(at(0).center.dx - 200, closeTo(200 - at(1).center.dx, 1e-9));
    expect(at(2).center.dx, greaterThan(at(0).center.dx));
    // 不压在人身上：离中线至少半个肩宽
    expect(at(0).left, greaterThan(200 + 400 * 0.12));
  });

  test('场景道具按固定位置排开，两侧优先', () {
    Rect at(int slot) =>
        scenePropRect(0.3, frameWidth: 400, feetY: 600, figureHeight: 300, slot: slot);
    expect(at(0).center.dx, closeTo(56, 1e-9));
    expect(at(1).center.dx, closeTo(344, 1e-9));
    expect(at(0).bottom, 600);
    expect(at(5).center, at(0).center);
  });
}
