import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_controller.dart' as input;
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';

Future<void> press(WidgetTester tester, String symbol) async {
  await tester.tap(
    find.descendant(
      of: find.byType(CalculatorKey),
      matching: find.text(symbol),
    ),
  );
  await tester.pumpAndSettle();
}

String current(WidgetTester tester) =>
    tester.widget<Display>(find.byType(Display, skipOffstage: false)).current;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    InputSettings.instance.load();
    Processor.restoreHistory();
    Processor.process(input.KeyEvent(const CalculatorKey(symbol: Keys.clear)));
  });

  testWidgets('copying history preserves input and confirms inside the sheet', (
    tester,
  ) async {
    var failClipboard = false;
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          if (failClipboard) {
            throw PlatformException(code: 'clipboard_unavailable');
          }
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();
    for (final symbol in ['1', '2', '×', '3', '=', 'C', '4']) {
      await press(tester, symbol);
    }
    expect(current(tester), '4');
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Copy calculation'));
    await tester.pumpAndSettle();
    expect(copied, ['12 × 3 = 36']);
    expect(current(tester), '4');
    expect(
      find.byKey(ValueKey(Processor.historyLog.single.id)),
      findsOneWidget,
    );
    final snack = tester.getRect(find.byType(SnackBar));
    final sheet = tester.getRect(find.byType(BottomSheet));
    expect(snack.top, greaterThanOrEqualTo(sheet.top));
    expect(snack.bottom, lessThanOrEqualTo(sheet.bottom));

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    failClipboard = true;
    await tester.tap(find.byTooltip('Copy calculation'));
    await tester.pumpAndSettle();
    expect(copied, hasLength(1));
    expect(find.text('Copied'), findsNothing);
    expect(current(tester), '4');
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.descendant(of: find.byType(Dismissible), matching: find.text('36')),
    );
    await tester.pumpAndSettle();
    expect(current(tester), '36');
    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(current(tester), '4');
  });

  testWidgets(
    'settings control feedback, keyboard works, and remount keeps one listener',
    (tester) async {
      var vibrations = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') vibrations++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('haptics-setting')));
      await tester.tap(find.byKey(const ValueKey('haptics-setting')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('shake-setting')));
      await tester.tap(find.byKey(const ValueKey('shake-setting')));
      await tester.pumpAndSettle();
      expect(InputSettings.instance.hapticsEnabled, isFalse);
      expect(InputSettings.instance.shakeToUndoEnabled, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit9, character: '9');
      await tester.pumpAndSettle();
      expect(current(tester), '0');
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      await press(tester, '1');
      expect(vibrations, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal, character: '+');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2, character: '2');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(current(tester), '3');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(current(tester), '2');

      // Recreating the screen must not close shared streams or double-process keys.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7, character: '7');
      await tester.pumpAndSettle();
      expect(current(tester), '7');
      expect(InputSettings.instance.hapticsEnabled, isFalse);
      expect(InputSettings.instance.shakeToUndoEnabled, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('startup restores saved history and it remains reusable', (
    tester,
  ) async {
    for (final symbol in [Keys.one, Keys.add, Keys.two, Keys.equals]) {
      Processor.process(input.KeyEvent(CalculatorKey(symbol: symbol)));
    }
    await HistoryStorage.instance.flush();
    // Startup must recover durable entries using the same cached preferences.
    Processor.restoreHistory();
    Processor.process(input.KeyEvent(const CalculatorKey(symbol: Keys.clear)));
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(S.current.history));
    await tester.pumpAndSettle();
    expect(find.text('1 + 2 ='), findsOneWidget);
    await tester.tap(
      find.descendant(of: find.byType(Dismissible), matching: find.text('3')),
    );
    await tester.pumpAndSettle();
    expect(current(tester), '3');
    await press(tester, '+');
    await press(tester, '4');
    await press(tester, '=');
    expect(current(tester), '7');
    expect(tester.takeException(), isNull);
  });
}
