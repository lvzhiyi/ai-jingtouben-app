import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/pages/preview/figure_pose.dart';

void main() {
  group('figureAction', () {
    test('按关键词选姿态，没有命中时站着', () {
      expect(figureAction('站在路口').pose, FigurePose.stand);
      expect(figureAction('她坐在窗边').pose, FigurePose.sit);
      expect(figureAction('沿着河边慢慢走').pose, FigurePose.walk);
      expect(figureAction('朝他挥手').pose, FigurePose.wave);
      expect(figureAction('转身离开').pose, FigurePose.back, reason: '「离开」比「转身」优先');
      expect(figureAction('听到声音回头').pose, FigurePose.turnBack);
      expect(figureAction('他走远了').pose, FigurePose.back, reason: '「走远」算背影，不算走');
    });

    test('视线：抬头、低头、对视、看不清脸', () {
      expect(figureAction('抬头看天').gaze, FigureGaze.up);
      expect(figureAction('低头看手机').gaze, FigureGaze.down);
      expect(figureAction('两人对视', count: 2).gaze, FigureGaze.eachOther);
      expect(figureAction('两人对视').gaze, FigureGaze.ahead, reason: '一个人不能对视');
      expect(figureAction('逆光里看不清脸').gaze, FigureGaze.hidden);
    });

    test('道具：伞、黑伞、手机；拿手机时不挥手', () {
      final umbrella = figureAction('撑着伞站在站台').props;
      expect(umbrella.umbrella, isTrue);
      expect(umbrella.darkUmbrella, isFalse);
      expect(figureAction('撑黑伞的男人').props.darkUmbrella, isTrue);
      final phone = figureAction('举手机挥手');
      expect(phone.props.phone, isTrue);
      expect(phone.pose, FigurePose.stand);
      expect(phone.props, const FigureProps(phone: true));
    });

    test('先去掉角色名再匹配', () {
      // 「走走」是名字，不该当成在走
      expect(figureAction('走走站在门口', ignore: ['走走']).pose, FigurePose.stand);
      expect(figureAction('走走站在门口').pose, FigurePose.walk);
    });

    test('背对镜头的姿态', () {
      expect(const FigureAction(pose: FigurePose.back).facingAway, isTrue);
      expect(const FigureAction(pose: FigurePose.turnBack).facingAway, isTrue);
      expect(const FigureAction().facingAway, isFalse);
      expect(const FigureAction(), const FigureAction());
    });
  });

  group('poseSkeleton', () {
    const stand = FigureAction();

    test('站立：头在最上、脚在最下，左右对称；呼吸起伏很小', () {
      final s = poseSkeleton(stand, seconds: 0);
      expect(s.top, closeTo(0, 1e-9));
      expect(s.footL.dy, closeTo(0.99, 1e-9));
      expect(s.handL.dx, -s.handR.dx);
      expect(s.seat, isNull);
      final breath = poseSkeleton(stand, seconds: 0.75);
      expect((breath.head.dy - s.head.dy).abs(), inInclusiveRange(0.001, 0.004));
      expect(breath.footL, s.footL, reason: '脚不跟着呼吸动');
    });

    test('走路：两条腿交替抬起', () {
      const walk = FigureAction(pose: FigurePose.walk);
      final a = poseSkeleton(walk, seconds: 0.3);
      final b = poseSkeleton(walk, seconds: 0.9);
      expect(a.footL.dy, lessThan(a.footR.dy));
      expect(b.footR.dy, lessThan(b.footL.dy));
    });

    test('坐下：上身下沉，有凳子，手放在膝盖附近', () {
      final s = poseSkeleton(const FigureAction(pose: FigurePose.sit), seconds: 0);
      expect(s.top, closeTo(sitDrop, 1e-9));
      expect(s.seat, isNotNull);
      expect((s.handL - s.kneeL).distance, lessThan(0.05));
    });

    test('挥手举过头，拿伞的手在胸前、伞面在头顶', () {
      final wave = poseSkeleton(const FigureAction(pose: FigurePose.wave), seconds: 0.2);
      expect(wave.handR.dy, lessThan(wave.shoulderR.dy));
      const umbrella = FigureAction(props: FigureProps(umbrella: true));
      final s = poseSkeleton(umbrella, seconds: 0);
      expect(s.handL.dy, lessThan(s.elbowL.dy));
      final shape = umbrellaShape(s);
      expect(shape.apex.dy, lessThan(shape.rimY));
      expect(shape.rimY, lessThan(s.top + 1e-9));
      // 伞杆在脸外侧，不挡脸
      expect(shape.apex.dx.abs(), greaterThan(Skeleton.headRadius));
      expect(shape.halfWidth, greaterThan(Skeleton.headRadius * 3));
    });

    test('拿手机的手在胸前', () {
      final s = poseSkeleton(const FigureAction(props: FigureProps(phone: true)), seconds: 0);
      expect(s.handR.dx.abs(), lessThan(0.08));
      expect(s.handR.dy, inInclusiveRange(s.shoulderR.dy, s.waistY));
    });
  });

  test('转头：对视转向对方，回头转向外侧，其余正对镜头', () {
    const facing = FigureAction(gaze: FigureGaze.eachOther);
    expect(headTurn(facing, centerX: 0.3), 1);
    expect(headTurn(facing, centerX: 0.7), -1);
    const turnBack = FigureAction(pose: FigurePose.turnBack);
    expect(headTurn(turnBack, centerX: 0.3), -1);
    expect(headTurn(turnBack, centerX: 0.5), 1);
    expect(headTurn(const FigureAction(), centerX: 0.3), 0);
  });
}
