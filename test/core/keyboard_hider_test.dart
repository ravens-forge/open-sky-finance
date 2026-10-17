import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/widgets/keyboard_hider.dart';

void main() {
  Future<FocusNode> pumpForm(WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyboardHider(child: child!),
        home: Scaffold(
          body: ListView(
            children: [
              TextField(key: const Key('first'), focusNode: focusNode),
              const TextField(key: Key('second')),
              FilledButton(onPressed: () {}, child: const Text('Save')),
              ListTile(title: const Text('Row'), onTap: () {}),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    return focusNode;
  }

  testWidgets('a tap on an empty area closes the keyboard', (tester) async {
    final focusNode = await pumpForm(tester);
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  for (final control in ['Save', 'Row']) {
    testWidgets('a tap on "$control" closes the keyboard', (tester) async {
      final focusNode = await pumpForm(tester);
      await tester.tap(find.text(control));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });
  }

  testWidgets('a tap on the field keeps the keyboard', (tester) async {
    final focusNode = await pumpForm(tester);
    await tester.tap(find.byKey(const Key('first')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('a tap on another field moves the focus to it', (tester) async {
    final focusNode = await pumpForm(tester);
    await tester.tap(find.byKey(const Key('second')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('scrolling keeps the keyboard', (tester) async {
    final focusNode = await pumpForm(tester);
    await tester.dragFrom(const Offset(200, 500), const Offset(0, -300));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });
}
