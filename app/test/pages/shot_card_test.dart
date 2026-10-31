import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/pages/storyboard/widgets/shot_card.dart';
import 'package:jingtouben/resources/theme.dart';

void main() {
  testWidgets('镜头卡片展示景别、画面、台词和拍摄理由', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ShotCard(
            shot: ShotDraft(
              index: 0,
              shotSize: ShotSize.closeUp,
              scene: '林夏回头',
              dialogue: '是你？',
              reason: '放大情绪',
            ),
          ),
        ),
      ),
    );

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('特写'), findsOneWidget);
    expect(find.text('林夏回头'), findsOneWidget);
    expect(find.text('「是你？」'), findsOneWidget);
    expect(find.text('放大情绪'), findsOneWidget);
  });
}
