import 'dart:math' as math;
import 'dart:ui';

/// 预演人物的姿态：按画面描述里的关键词选姿态、视线和手里的道具，再算出木偶人各关节的位置。
/// 全部是纯函数，本地匹配，不调用模型。
///
/// 人体坐标：x 以身体中线为 0、往画面右为正，y 从头顶 0 到脚底 1，单位都是身高。
/// 「左」「右」都指画面上的左右。

/// 身体姿态。
enum FigurePose {
  stand,
  walk,
  sit,

  /// 抬手、挥手（画面右边那只手）。
  wave,

  /// 背影：看不到脸。
  back,

  /// 回头：背对镜头，脸转到一侧。
  turnBack,
}

/// 视线和脸。
enum FigureGaze {
  ahead,
  up,
  down,

  /// 两人对视：脸转向对方。
  eachOther,

  /// 看不清脸（逆光、背光、帽檐或伞下的阴影）。
  hidden,
}

/// 手里的道具。伞拿在画面左边那只手，手机在右边那只手，两样可以同时有。
class FigureProps {
  const FigureProps({this.umbrella = false, this.darkUmbrella = false, this.phone = false});

  final bool umbrella;
  final bool darkUmbrella;
  final bool phone;

  @override
  bool operator ==(Object other) =>
      other is FigureProps &&
      other.umbrella == umbrella &&
      other.darkUmbrella == darkUmbrella &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(umbrella, darkUmbrella, phone);
}

/// 一个镜头里人物的动作：同一镜里出场的人共用一套。
class FigureAction {
  const FigureAction({
    this.pose = FigurePose.stand,
    this.gaze = FigureGaze.ahead,
    this.props = const FigureProps(),
  });

  final FigurePose pose;
  final FigureGaze gaze;
  final FigureProps props;

  /// 背对镜头。
  bool get facingAway => pose == FigurePose.back || pose == FigurePose.turnBack;

  @override
  bool operator ==(Object other) =>
      other is FigureAction && other.pose == pose && other.gaze == gaze && other.props == props;

  @override
  int get hashCode => Object.hash(pose, gaze, props);
}

/// 关键词按优先级排：「走远」先算背影，「转身」算回头。
const _poseKeywords = <FigurePose, List<String>>{
  FigurePose.back: ['背影', '背对', '离开', '走远', '远去', '离去'],
  FigurePose.turnBack: ['回头', '回望', '回首', '转身'],
  FigurePose.sit: ['坐'],
  FigurePose.walk: ['走', '跑', '奔', '赶路', '漫步', '散步'],
  FigurePose.wave: ['挥手', '招手', '举手', '抬手'],
};

const _gazeKeywords = <FigureGaze, List<String>>{
  FigureGaze.hidden: ['看不清脸', '背光', '逆光', '剪影'],
  FigureGaze.eachOther: ['对视', '相视', '面对面', '四目相对', '看着对方'],
  FigureGaze.down: ['低头', '俯视', '看手机', '看着手机'],
  FigureGaze.up: ['抬头', '仰望', '仰头'],
};

/// 画面描述 → 人物动作。[ignore] 传出场角色名，先从描述里去掉；[count] 是画面里的人数，
/// 一个人时不会「对视」。
FigureAction figureAction(String scene, {List<String> ignore = const [], int count = 1}) {
  for (final name in ignore) {
    if (name.isNotEmpty) scene = scene.replaceAll(name, ' ');
  }
  T pick<T>(Map<T, List<String>> table, T fallback) {
    for (final MapEntry(:key, :value) in table.entries) {
      if (value.any(scene.contains)) return key;
    }
    return fallback;
  }

  var pose = pick(_poseKeywords, FigurePose.stand);
  var gaze = pick(_gazeKeywords, FigureGaze.ahead);
  if (gaze == FigureGaze.eachOther && count < 2) gaze = FigureGaze.ahead;
  final props = FigureProps(
    umbrella: scene.contains('伞'),
    darkUmbrella: scene.contains('黑伞'),
    phone: scene.contains('手机'),
  );
  // 挥手和拿手机用的是同一只手，拿手机优先
  if (pose == FigurePose.wave && props.phone) pose = FigurePose.stand;
  return FigureAction(pose: pose, gaze: gaze, props: props);
}

/// 木偶人各关节的位置（人体坐标）。
class Skeleton {
  const Skeleton({
    required this.head,
    required this.neck,
    required this.shoulderL,
    required this.shoulderR,
    required this.elbowL,
    required this.elbowR,
    required this.handL,
    required this.handR,
    required this.hipL,
    required this.hipR,
    required this.kneeL,
    required this.kneeR,
    required this.footL,
    required this.footR,
    this.seat,
  });

  /// 头部中心，头的半径是 [headRadius]。
  final Offset head;
  final Offset neck;
  final Offset shoulderL;
  final Offset shoulderR;
  final Offset elbowL;
  final Offset elbowR;
  final Offset handL;
  final Offset handR;
  final Offset hipL;
  final Offset hipR;
  final Offset kneeL;
  final Offset kneeR;
  final Offset footL;
  final Offset footR;

  /// 坐着时身后的凳子（人体坐标的矩形），其余姿态为空。
  final Rect? seat;

  static const headRadius = 0.06;

  /// 腰（胸腔下沿）的高度。
  double get waistY => (shoulderL.dy + shoulderR.dy) / 2 + 0.235;

  /// 头顶的高度：坐下时整个上身往下沉。
  double get top => head.dy - headRadius;
}

/// 坐下时上身往下沉的距离（身高的比例）。
const sitDrop = 0.2;

/// 姿态 → [seconds]（镜头内已播秒数）时刻的骨架。站着也有轻微的呼吸起伏，走路时手脚交替摆动。
Skeleton poseSkeleton(FigureAction action, {required double seconds}) {
  // 呼吸：约 3 秒一次，肩膀和头起伏 0.3% 身高
  final breath = 0.003 * math.sin(seconds * 2 * math.pi / 3);
  final pose = action.pose;
  final sit = pose == FigurePose.sit;
  final drop = sit ? sitDrop : 0.0;
  final upper = drop - breath;

  // 走路：每秒约 1.6 步，抬起的那条腿膝盖和脚往上收，同侧手臂往后（画面上看是手往上收得少）
  final step = pose == FigurePose.walk ? math.sin(seconds * 2 * math.pi * 0.8) : 0.0;
  final liftL = math.max(0.0, step);
  final liftR = math.max(0.0, -step);
  final bob = pose == FigurePose.walk ? 0.006 * step.abs() : 0.0;

  Offset up(double x, double y) => Offset(x, y + upper - bob);

  var elbowL = up(-0.13, 0.36 - 0.015 * liftR);
  var elbowR = up(0.13, 0.36 - 0.015 * liftL);
  var handL = up(-0.125, 0.53 - 0.04 * liftR);
  var handR = up(0.125, 0.53 - 0.04 * liftL);
  var kneeL = Offset(-0.06, 0.77 - 0.05 * liftL);
  var kneeR = Offset(0.06, 0.77 - 0.05 * liftR);
  var footL = Offset(-0.055, 0.99 - 0.07 * liftL);
  var footR = Offset(0.055, 0.99 - 0.07 * liftR);
  Rect? seat;

  if (sit) {
    // 正面看坐姿：大腿朝镜头，膝盖略低于胯、往外分，小腿垂直，手放在膝盖上
    kneeL = const Offset(-0.085, 0.8);
    kneeR = const Offset(0.085, 0.8);
    footL = const Offset(-0.08, 0.99);
    footR = const Offset(0.08, 0.99);
    elbowL = up(-0.14, 0.4);
    elbowR = up(0.14, 0.4);
    handL = Offset(-0.08, 0.76 - breath);
    handR = Offset(0.08, 0.76 - breath);
    seat = const Rect.fromLTWH(-0.17, 0.74, 0.34, 0.25);
  }
  if (pose == FigurePose.wave) {
    // 画面右边的手举过肩，左右轻摆，约每秒两次
    elbowR = up(0.2, 0.2);
    handR = up(0.2 + 0.035 * math.sin(seconds * 2 * math.pi * 2), 0.03);
  }
  if (action.props.umbrella) {
    // 左手在胸前握伞柄，伞杆在脸的左外侧，不挡脸
    elbowL = up(-0.15, 0.35);
    handL = up(-0.075, 0.3);
  }
  if (action.props.phone) {
    // 右手端着手机在胸前
    elbowR = up(0.14, 0.37);
    handR = up(0.05, 0.27);
  }

  return Skeleton(
    head: up(0, 0.06),
    neck: up(0, 0.13),
    shoulderL: up(-0.11, 0.155),
    shoulderR: up(0.11, 0.155),
    elbowL: elbowL,
    elbowR: elbowR,
    handL: handL,
    handR: handR,
    hipL: Offset(-0.055, 0.55 + drop - bob),
    hipR: Offset(0.055, 0.55 + drop - bob),
    kneeL: kneeL,
    kneeR: kneeR,
    footL: footL,
    footR: footR,
    seat: seat,
  );
}

/// 伞（人体坐标）：伞顶、伞面左右沿的中点和半宽。伞杆从左手竖直往上到伞顶。
({Offset apex, double rimY, double halfWidth}) umbrellaShape(Skeleton skeleton) {
  final x = skeleton.handL.dx;
  return (apex: Offset(x, skeleton.top - 0.13), rimY: skeleton.top - 0.01, halfWidth: 0.26);
}

/// 脸往哪边转：-1 向画面左、1 向画面右、0 正对镜头。对视时转向画面中间的另一个人；
/// 回头时转向画框外侧那边，人在画面中间时转向右。
double headTurn(FigureAction action, {required double centerX}) {
  if (action.pose == FigurePose.turnBack) return centerX < 0.45 ? -1 : 1;
  if (action.gaze == FigureGaze.eachOther) return centerX < 0.5 ? 1 : -1;
  return 0;
}
