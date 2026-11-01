import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/pages/characters/widgets/character_editor_dialog.dart';

void main() {
  testWidgets('重名或名字为空时提示且不关闭，填好后返回去掉首尾空格的资料', (tester) async {
    CharacterProfile? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<CharacterProfile>(
                context: context,
                builder: (_) => CharacterEditorDialog(isNameTaken: (name) => name == '初恋'),
              );
              closed = true;
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('请填写角色名'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '角色名'), '初恋');
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('已经有叫「初恋」的角色了'), findsOneWidget);
    expect(closed, isFalse);

    await tester.enterText(find.widgetWithText(TextField, '角色名'), ' 我 ');
    await tester.enterText(find.widgetWithText(TextField, '服装'), '黑色雨衣 ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, const CharacterProfile(name: '我', outfit: '黑色雨衣'));
  });
}
