import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/calculator_shortcuts.dart';
import 'package:simple_calculator/key_symbol.dart';

Widget _harness({
  required ValueChanged<KeySymbol> onKey,
  required VoidCallback onUndo,
}) {
  return MaterialApp(
    home: Scaffold(
      body: CalculatorShortcuts(
        onKey: onKey,
        onUndo: onUndo,
        child: Builder(
          builder: (context) => Column(
            children: [
              const Text('Calculator'),
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Dialog'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close dialog'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Open dialog'),
              ),
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close sheet'),
                  ),
                ),
                child: const Text('Open sheet'),
              ),
              TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back from settings'),
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key, character: character);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Future<void> _undo(WidgetTester tester, LogicalKeyboardKey modifier) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, character: 'z');
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('main and numpad digits each dispatch one input', (tester) async {
    final events = <KeySymbol>[];
    await tester.pumpWidget(_harness(onKey: events.add, onUndo: () {}));
    await tester.pumpAndSettle();
    const digitKeys = [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = [
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];
    for (final keys in [digitKeys, numpadKeys]) {
      for (var i = 0; i < keys.length; i++) {
        final before = events.length;
        await _press(tester, keys[i], character: '$i');
        expect(events.length, before + 1);
        expect(events.last.value, '$i');
      }
    }
  });

  testWidgets('operators, shifted characters, and editing keys dispatch once', (
    tester,
  ) async {
    final events = <KeySymbol>[];
    await tester.pumpWidget(_harness(onKey: events.add, onUndo: () {}));
    await tester.pumpAndSettle();
    final cases = <(LogicalKeyboardKey, String?, bool, KeySymbol)>[
      (LogicalKeyboardKey.equal, '+', true, Keys.add),
      (LogicalKeyboardKey.minus, '-', false, Keys.subtract),
      (LogicalKeyboardKey.digit8, '*', true, Keys.multiply),
      (LogicalKeyboardKey.slash, '/', false, Keys.divide),
      (LogicalKeyboardKey.digit5, '%', true, Keys.percent),
      (LogicalKeyboardKey.period, '.', false, Keys.decimal),
      (LogicalKeyboardKey.equal, '=', false, Keys.equals),
      (LogicalKeyboardKey.enter, null, false, Keys.equals),
      (LogicalKeyboardKey.numpadEnter, null, false, Keys.equals),
      (LogicalKeyboardKey.backspace, null, false, Keys.back),
      (LogicalKeyboardKey.escape, null, false, Keys.clear),
      (LogicalKeyboardKey.numpadAdd, '+', false, Keys.add),
      (LogicalKeyboardKey.numpadSubtract, '-', false, Keys.subtract),
      (LogicalKeyboardKey.numpadMultiply, '*', false, Keys.multiply),
      (LogicalKeyboardKey.numpadDivide, '/', false, Keys.divide),
      (LogicalKeyboardKey.numpadDecimal, '.', false, Keys.decimal),
    ];
    for (final example in cases) {
      final before = events.length;
      await _press(
        tester,
        example.$1,
        character: example.$2,
        shift: example.$3,
      );
      expect(
        events.length,
        before + 1,
        reason: 'Key ${example.$1} / ${example.$2}',
      );
      expect(events.last, example.$4);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('held keys cannot repeat calculator input or undo', (
    tester,
  ) async {
    final events = <KeySymbol>[];
    var undos = 0;
    await tester.pumpWidget(_harness(onKey: events.add, onUndo: () => undos++));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit1, character: '1');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit1, character: '1');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit1, character: '1');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect(events, [Keys.one]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ, character: 'z');
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyZ, character: 'z');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(undos, 1);
  });

  testWidgets(
    'Control and Command undo work while unrelated chords are ignored',
    (tester) async {
      final events = <KeySymbol>[];
      var undos = 0;
      await tester.pumpWidget(
        _harness(onKey: events.add, onUndo: () => undos++),
      );
      await tester.pumpAndSettle();
      await _undo(tester, LogicalKeyboardKey.controlLeft);
      await _undo(tester, LogicalKeyboardKey.metaLeft);
      expect(undos, 2);

      for (final modifier in [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.altLeft,
      ]) {
        await tester.sendKeyDownEvent(modifier);
        await _press(tester, LogicalKeyboardKey.digit1, character: '1');
        await _press(tester, LogicalKeyboardKey.equal, character: '+');
        await tester.sendKeyUpEvent(modifier);
      }
      await _press(tester, LogicalKeyboardKey.keyA, character: 'a');
      expect(events, isEmpty);
      expect(undos, 2);
    },
  );

  for (final route in <(String, String)>[
    ('Open dialog', 'Close dialog'),
    ('Open sheet', 'Close sheet'),
    ('Open settings', 'Back from settings'),
  ]) {
    testWidgets('shortcuts pause during ${route.$1} and resume after closing', (
      tester,
    ) async {
      final events = <KeySymbol>[];
      var undos = 0;
      await tester.pumpWidget(
        _harness(onKey: events.add, onUndo: () => undos++),
      );
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.digit1, character: '1');
      expect(events, [Keys.one]);

      await tester.tap(find.text(route.$1));
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.digit9, character: '9');
      await _press(
        tester,
        LogicalKeyboardKey.equal,
        character: '+',
        shift: true,
      );
      await _undo(tester, LogicalKeyboardKey.controlLeft);
      expect(events, [Keys.one]);
      expect(undos, 0);

      await tester.tap(find.text(route.$2));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text(route.$1))).requestFocus();
      await tester.pumpAndSettle();
      await _press(tester, LogicalKeyboardKey.digit2, character: '2');
      await _press(tester, LogicalKeyboardKey.enter);
      await _undo(tester, LogicalKeyboardKey.metaLeft);
      expect(events, [Keys.one, Keys.two, Keys.equals]);
      expect(undos, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
