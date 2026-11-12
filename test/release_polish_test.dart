import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/history_sheet.dart';
import 'package:simple_calculator/key_controller.dart' as input;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/main.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

void main() {
  group('calculator engine', () {
    late CalcState state;
    late StreamSubscription<CalcState> subscription;

    Future<void> flush() => Future<void>.delayed(Duration.zero);

    Future<void> press(List<KeySymbol> symbols) async {
      for (final symbol in symbols) {
        Processor.process(input.KeyEvent(CalculatorKey(symbol: symbol)));
      }
      await flush();
    }

    setUp(() async {
      subscription = Processor.listen((value) => state = value);
      Processor.refresh();
      await flush();
    });

    tearDown(() async {
      while (Processor.canUndo) {
        Processor.undo();
      }
      Processor.clearHistory();
      await flush();
      await subscription.cancel();
    });

    test('floating-point noise is rounded away', () async {
      await press([
        Keys.zero,
        Keys.decimal,
        Keys.one,
        Keys.add,
        Keys.zero,
        Keys.decimal,
        Keys.two,
        Keys.equals,
      ]);
      expect(state.current, '0.3');
    });

    test('zero times a negative shows 0, not -0', () async {
      await press([Keys.five, Keys.sign, Keys.multiply, Keys.zero]);
      await press([Keys.equals]);
      expect(state.current, '0');
    });

    test('typing a digit after a result starts a new number', () async {
      await press([Keys.two, Keys.add, Keys.three, Keys.equals, Keys.seven]);
      expect(state.current, '7');
      expect(state.history, isEmpty);
      // Operators still continue from the result.
      await press([Keys.add, Keys.one, Keys.equals]);
      expect(state.current, '8');
      expect(state.history, '7 + 1 =');
    });

    test('pressing = again does not duplicate history', () async {
      await press([Keys.two, Keys.add, Keys.three, Keys.equals, Keys.equals]);
      expect(state.current, '5');
      expect(Processor.historyLog, hasLength(1));
    });

    test('continuing after equals records each calculation once', () async {
      await press([Keys.two, Keys.add, Keys.three, Keys.equals]);
      final original = Processor.historyLog.single;

      await press([Keys.multiply]);
      expect(state.current, '5');
      expect(state.history, '5 ×');
      expect(state.isResult, isFalse);
      expect(Processor.historyLog, [original]);

      await press([Keys.four, Keys.subtract]);
      expect(state.current, '20');
      expect(state.history, '20 -');
      expect(Processor.historyLog.map((entry) => entry.equation), [
        '5 × 4 =',
        original.equation,
      ]);

      await press([Keys.one, Keys.equals]);
      expect(state.current, '19');
      expect(state.history, '20 - 1 =');
      expect(
        Processor.historyLog.map((entry) => (entry.equation, entry.result)),
        [('20 - 1 =', '19'), ('5 × 4 =', '20'), ('2 + 3 =', '5')],
      );
      expect(Processor.historyLog.last.id, original.id);
    });

    test('a trailing decimal point is accepted and tidied', () async {
      await press([Keys.decimal, Keys.add, Keys.five, Keys.decimal]);
      await press([Keys.equals]);
      expect(state.current, '5');
      expect(state.history, '0 + 5 =');
    });

    test('rejected key presses do not use up undo steps', () async {
      await press([Keys.one, Keys.decimal, Keys.decimal, Keys.decimal]);
      Processor.undo();
      await flush();
      expect(state.current, '1');
    });

    test('paste accepts single numbers and rejects other text', () {
      expect(Processor.parsePastedNumber(' 1,234.5 '), '1234.5');
      expect(Processor.parsePastedNumber('−3'), '-3');
      expect(Processor.parsePastedNumber('+2.5e3'), '2500');
      expect(Processor.parsePastedNumber('12,34'), isNull);
      expect(Processor.parsePastedNumber('1+2'), isNull);
      expect(Processor.parsePastedNumber('abc'), isNull);
      expect(Processor.parsePastedNumber(''), isNull);
    });

    test('paste fills the operand being typed and is undoable', () async {
      await press([Keys.four, Keys.multiply]);
      expect(Processor.paste('2.5'), isTrue);
      await flush();
      expect(state.current, '2.5');
      await press([Keys.equals]);
      expect(state.current, '10');
      Processor.undo();
      Processor.undo();
      await flush();
      expect(state.current, '4');
      expect(Processor.paste('nope'), isFalse);
    });

    test('a deleted history entry can be restored in place', () async {
      for (final digit in [Keys.one, Keys.two, Keys.three]) {
        await press([digit, Keys.add, digit, Keys.equals]);
      }
      final middle = Processor.historyLog[1];
      final deletion = Processor.removeHistoryEntry(middle.id)!;
      expect(Processor.historyLog.map((e) => e.result), ['6', '2']);
      expect(Processor.restoreHistoryEntry(deletion), isTrue);
      expect(Processor.historyLog.map((e) => e.result), ['6', '4', '2']);
      expect(Processor.restoreHistoryEntry(deletion), isFalse);
    });
  });

  group('screens', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageManager.init();
      InputSettings.instance.load();
      Processor.restoreHistory();
      Processor.process(
        input.KeyEvent(const CalculatorKey(symbol: Keys.clear)),
      );
    });

    String current(WidgetTester tester) =>
        tester.widget<Display>(find.byType(Display)).current;

    Future<void> press(WidgetTester tester, String symbol) async {
      await tester.tap(
        find.descendant(
          of: find.byType(CalculatorKey),
          matching: find.text(symbol),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('changing the theme recolors the calculator immediately', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      final model = Provider.of<ThemeModel>(
        tester.element(find.byType(Calculator)),
        listen: false,
      );
      Color keyColor() => (tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(CalculatorKey),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration! as BoxDecoration)
              .color!;

      model.switchTheme(3);
      await tester.pumpAndSettle();
      expect(keyColor(), model.buttonColor3);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        model.backgroundColor,
      );
      model.switchTheme(0);
      await tester.pumpAndSettle();
    });

    testWidgets('paste button enters a copied number', (tester) async {
      String? clipboard = '1,250';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboard};
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

      await tester.tap(find.byTooltip('Paste number'));
      await tester.pumpAndSettle();
      expect(current(tester), '1250');
      expect(find.text('Number pasted'), findsOneWidget);

      clipboard = '2 + 2';
      await tester.tap(find.byTooltip('Paste number'));
      await tester.pumpAndSettle();
      expect(current(tester), '1250');
      expect(find.text('Copy a valid number to paste.'), findsOneWidget);
    });

    testWidgets(
      'keyboard copy follows the calculator display and focused history search',
      (tester) async {
        final clipboardWrites = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardWrites.add((call.arguments as Map)['text'] as String);
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

        Future<void> copyWith(LogicalKeyboardKey modifier) async {
          await tester.sendKeyDownEvent(modifier);
          await tester.sendKeyEvent(LogicalKeyboardKey.keyC, character: 'c');
          await tester.sendKeyUpEvent(modifier);
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(const CalculatorApp());
        await tester.pumpAndSettle();
        for (final symbol in ['1', '2', '3', '4']) {
          await press(tester, symbol);
        }
        expect(find.text('1,234'), findsOneWidget);
        await copyWith(LogicalKeyboardKey.controlLeft);
        await copyWith(LogicalKeyboardKey.metaLeft);
        expect(clipboardWrites, ['1234', '1234']);

        for (final symbol in ['÷', '0', '=']) {
          await press(tester, symbol);
        }
        expect(find.text('Error'), findsOneWidget);
        await copyWith(LogicalKeyboardKey.controlLeft);
        await copyWith(LogicalKeyboardKey.metaLeft);
        expect(clipboardWrites, ['1234', '1234']);

        await press(tester, '7');
        await tester.tap(find.byTooltip('History'));
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('history-search'));
        await tester.enterText(search, 'history query');
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: 'history query',
            selection: TextSelection(baseOffset: 0, extentOffset: 7),
          ),
        );
        await tester.pumpAndSettle();
        await copyWith(
          defaultTargetPlatform == TargetPlatform.macOS
              ? LogicalKeyboardKey.metaLeft
              : LogicalKeyboardKey.controlLeft,
        );
        expect(clipboardWrites, ['1234', '1234', 'history']);
        expect(current(tester), '7');
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }),
    );

    testWidgets('the display copies an equation only while it is complete', (
      tester,
    ) async {
      final clipboardWrites = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardWrites.add((call.arguments as Map)['text'] as String);
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

      final copyEquation = find.bySemanticsLabel('Copy calculation');
      for (final symbol in ['1', '2', '0', '0', '+', '3', '4']) {
        await press(tester, symbol);
      }
      expect(copyEquation, findsNothing);
      await tester.tap(find.text('1200 +'));
      await tester.pumpAndSettle();
      expect(clipboardWrites, isEmpty);

      await press(tester, '=');
      final equation = find.text('1200 + 34 =');
      final equationPosition = tester.getCenter(equation);
      final history = Processor.historyLog;
      await tester.tap(equation);
      await tester.pumpAndSettle();
      expect(clipboardWrites, ['1200 + 34 = 1234']);
      expect(find.text('Copied'), findsOneWidget);

      final node = tester.getSemantics(copyEquation);
      expect(
        node,
        isSemantics(value: '1200 + 34 =', isButton: true, hasTapAction: true),
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1,234'));
      await tester.pumpAndSettle();
      final expectedCopies = ['1200 + 34 = 1234', '1200 + 34 = 1234', '1234'];
      expect(clipboardWrites, expectedCopies);
      expect(Processor.historyLog, history);

      await tester.tap(find.text('÷'));
      await tester.pump();
      expect(find.text('1234 ÷'), findsOneWidget);
      expect(equation, findsOneWidget);
      expect(copyEquation, findsNothing);
      await tester.tapAt(equationPosition);
      await tester.pumpAndSettle();
      expect(clipboardWrites, expectedCopies);

      await press(tester, '0');
      await press(tester, '=');
      expect(find.text('Error'), findsOneWidget);
      expect(copyEquation, findsNothing);
      await tester.tap(find.text('Error'));
      await tester.pumpAndSettle();
      expect(clipboardWrites, expectedCopies);
      expect(tester.takeException(), isNull);
    });

    testWidgets('history search, swipe delete, and undo', (tester) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      for (final symbol in ['1', '2', '+', '3', '=', '4', '×', '5', '=']) {
        await press(tester, symbol);
      }
      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      Finder inSheet(String text) => find.descendant(
        of: find.byType(HistorySheet),
        matching: find.text(text),
      );

      await tester.enterText(find.byKey(const ValueKey('history-search')), '×');
      await tester.pumpAndSettle();
      expect(inSheet('4 × 5 ='), findsOneWidget);
      expect(inSheet('12 + 3 ='), findsNothing);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(inSheet('12 + 3 ='), findsOneWidget);

      await tester.drag(inSheet('12 + 3 ='), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(inSheet('12 + 3 ='), findsNothing);
      expect(Processor.historyLog, hasLength(1));
      await tester.tap(find.text('Undo').last);
      await tester.pumpAndSettle();
      expect(inSheet('12 + 3 ='), findsOneWidget);
      expect(Processor.historyLog, hasLength(2));
    });

    testWidgets('tips explain how to copy results, equations, and history', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      final strings = S.of(tester.element(find.byType(MorePage)));
      await tester.tap(find.text(strings.helpAndShortcuts));
      await tester.pumpAndSettle();

      expect(find.text(strings.helpCopy), findsOneWidget);
      expect(find.text(strings.helpCopyHistory), findsOneWidget);
    });

    testWidgets('tips explain how to open and use the Premium tools', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tips and shortcuts'));
      await tester.pumpAndSettle();

      final formulasTip = find.text(
        'In Reusable formulas, open an example to edit its inputs and compare two scenarios.',
      );
      await tester.ensureVisible(formulasTip);
      await tester.pumpAndSettle();

      expect(find.text('SwiftSum Premium').hitTestable(), findsOneWidget);
      expect(
        find
            .text(
              'Tap Premium tools in the calculator toolbar to open the scientific calculator or reusable formulas.',
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        find
            .text(
              'Choose Degrees or Radians in the scientific calculator before using trigonometric functions.',
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(formulasTip.hitTestable(), findsOneWidget);
    });

    testWidgets('theme tiles support accessibility and pointer activation', (
      tester,
    ) async {
      await tester.pumpWidget(const CalculatorApp());
      await tester.pumpAndSettle();
      final model = Provider.of<ThemeModel>(
        tester.element(find.byType(Calculator)),
        listen: false,
      );
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(MorePage), findsOneWidget);

      final defaultTheme = find.bySemanticsLabel('Theme 1');
      final alternateTheme = find.bySemanticsLabel('Theme 2');
      expect(
        tester.getSemantics(defaultTheme),
        isSemantics(label: 'Theme 1', isButton: true, isSelected: true),
      );
      final node = tester.getSemantics(alternateTheme);
      expect(
        node,
        isSemantics(
          label: 'Theme 2',
          isButton: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(model.themeColor, 1);
      expect(
        tester.getSemantics(alternateTheme),
        isSemantics(label: 'Theme 2', isButton: true, isSelected: true),
      );
      final preferences = StorageManager.sharedPreferences!;
      await preferences.reload();
      expect(preferences.getInt(ThemeModel.kThemeColorIndex), 1);

      await tester.tap(defaultTheme);
      await tester.pumpAndSettle();
      expect(model.themeColor, 0);
    });
  });
}
