import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/line_accumulator.dart';
import 'package:jingtouben/data/storyboard/shot_line_parser.dart';

void main() {
  const parser = ShotLineParser();

  group('ShotLineParser', () {
    test('合法的一行直接解析成功', () {
      final result = parser.parse(
        '{"shotSize":"特写","scene":"林夏回头","dialogue":"是你？","reason":"放大情绪","characters":["林夏"]}',
        index: 2,
      );
      expect(result, isA<ParsedShot>());
      final parsed = result as ParsedShot;
      expect(parsed.repaired, isFalse);
      expect(parsed.shot.index, 2);
      expect(parsed.shot.shotSize, ShotSize.closeUp);
      expect(parsed.shot.characters, ['林夏']);
      expect(parsed.shot.warnings, isEmpty);
    });

    test('行尾逗号和编号前缀可以修复', () {
      for (final line in [
        '{"shotSize":"中景","scene":"街口","reason":"交代位置"},',
        '1. {"shotSize":"中景","scene":"街口","reason":"交代位置",}',
      ]) {
        final result = parser.parse(line, index: 0);
        expect(result, isA<ParsedShot>(), reason: line);
        expect((result as ParsedShot).repaired, isTrue);
      }
    });

    test('输出被截断时补齐引号和括号', () {
      final result = parser.parse('{"shotSize":"近景","scene":"雨水滴落', index: 0);
      expect(result, isA<ParsedShot>());
      expect((result as ParsedShot).shot.scene, '雨水滴落');
    });

    test('景别不在枚举里时按中景兜底并提示', () {
      final result = parser.parse('{"shotSize":"鸟瞰","scene":"城市夜景","reason":"x"}', index: 0);
      final shot = (result as ParsedShot).shot;
      expect(shot.shotSize, ShotSize.medium);
      expect(shot.warnings, contains('景别无法识别，已按中景处理'));
    });

    test('缺少画面描述或无法修复时标记为需要重新生成', () {
      expect(parser.parse('{"shotSize":"中景"}', index: 3), isA<BrokenShot>());
      final broken = parser.parse('这不是 JSON', index: 4);
      expect(broken, isA<BrokenShot>());
      expect((broken as BrokenShot).index, 4);
    });

    test('空行和代码块标记被忽略', () {
      expect(parser.parse('   ', index: 0), isA<SkippedLine>());
      expect(parser.parse('```json', index: 0), isA<SkippedLine>());
    });
  });

  group('LineAccumulator', () {
    test('一行被拆进多个增量时，遇到换行才交出', () {
      final lines = LineAccumulator();
      expect(lines.add('{"a":'), isEmpty);
      expect(lines.add('1}\n{"b"'), ['{"a":1}']);
      expect(lines.add(':2}\r\n'), ['{"b":2}']);
      expect(lines.flush(), isEmpty);
    });

    test('最后一行没有换行时在 flush 交出', () {
      final lines = LineAccumulator()..add('{"c":3}');
      expect(lines.flush(), ['{"c":3}']);
    });
  });
}
