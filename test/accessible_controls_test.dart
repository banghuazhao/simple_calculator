import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_controller.dart' as calculator;
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/theme_model.dart';

Widget _harness(Widget child, {Locale locale = const Locale('en')}) {
  return ChangeNotifierProvider(
    create: (_) => ThemeModel(),
    child: MaterialApp(
      locale: locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  final events = <calculator.KeyEvent>[];
  late StreamSubscription<dynamic> subscription;

  setUpAll(() {
    subscription = calculator.KeyController.listen(
      (dynamic event) => events.add(event as calculator.KeyEvent),
    );
  });
  setUp(events.clear);
  tearDownAll(() => subscription.cancel());

  testWidgets('keypad touch and accessibility taps each fire one key event', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(const CalculatorKey(symbol: Keys.divide)));
    await tester.pumpAndSettle();

    final key = find.bySemanticsLabel('Divide');
    expect(
      tester.getSemantics(key),
      matchesSemantics(label: 'Divide', isButton: true, hasTapAction: true),
    );

    await tester.tap(key);
    await tester.pumpAndSettle();
    expect(events.map((event) => event.key.symbol), [Keys.divide]);

    final node = tester.getSemantics(key);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(events.map((event) => event.key.symbol), [Keys.divide, Keys.divide]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('function keys expose readable names without duplicate symbols', (
    tester,
  ) async {
    final labels = <KeySymbol, String>{
      Keys.clear: 'Clear input',
      Keys.sign: 'Change sign',
      Keys.percent: 'Percent',
      Keys.divide: 'Divide',
      Keys.multiply: 'Multiply',
      Keys.subtract: 'Subtract',
      Keys.add: 'Add',
      Keys.equals: 'Equals',
      Keys.decimal: 'Decimal point',
      Keys.back: 'Backspace',
      Keys.one: '1',
    };
    for (final entry in labels.entries) {
      await tester.pumpWidget(_harness(CalculatorKey(symbol: entry.key)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(entry.value), findsOneWidget);
      if (entry.key.value != entry.value) {
        expect(find.bySemanticsLabel(entry.key.value), findsNothing);
      }
    }
  });

  testWidgets(
    'unavailable haptics cannot interrupt touch or accessibility input',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            throw PlatformException(code: 'haptics_unavailable');
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

      await tester.pumpWidget(
        _harness(const CalculatorKey(symbol: Keys.divide)),
      );
      await tester.pumpAndSettle();
      final key = find.bySemanticsLabel('Divide');
      await tester.tap(key);
      await tester.pumpAndSettle();
      final node = tester.getSemantics(key);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(events.map((event) => event.key.symbol), [
        Keys.divide,
        Keys.divide,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('copy accessibility action keeps the unformatted numeric value', (
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

    await tester.pumpWidget(
      _harness(const Display(current: '1234.50', history: '', isResult: true)),
    );
    await tester.pumpAndSettle();
    final copy = find.bySemanticsLabel('Copy result');
    final node = tester.getSemantics(copy);
    expect(
      node,
      matchesSemantics(
        label: 'Copy result',
        value: '1,234.50',
        isButton: true,
        hasTapAction: true,
      ),
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(clipboardWrites, ['1234.50']);
    expect(find.text('Copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard failure is handled without a false success message', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard_unavailable');
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

    await tester.pumpWidget(
      _harness(const Display(current: '42', history: '')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('42'));
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error display exposes no copy action', (tester) async {
    var clipboardWrites = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardWrites++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      _harness(const Display(current: 'Error', history: '')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Error')),
      matchesSemantics(label: 'Error'),
    );
    await tester.tap(find.text('Error'));
    await tester.pumpAndSettle();
    expect(clipboardWrites, 0);
    expect(find.text('Copied'), findsNothing);
  });

  testWidgets('finishing a clipboard write after leaving the screen is safe', (
    tester,
  ) async {
    final pending = Completer<void>();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') await pending.future;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      _harness(const Display(current: '42', history: '')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('42'));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [Locale('zh'), Locale('zh', 'HK')]) {
    testWidgets(
      'calculator controls and copy feedback are localized for $locale',
      (tester) async {
        final traditional = locale.countryCode == 'HK';
        final copyLabel = traditional ? '複製結果' : '复制结果';
        final copiedLabel = traditional ? '已複製' : '已复制';
        final errorLabel = traditional ? '錯誤' : '错误';
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

        await tester.pumpWidget(
          _harness(
            const Column(
              children: [
                CalculatorKey(symbol: Keys.divide),
                Expanded(
                  child: Display(current: '1234.5', history: ''),
                ),
              ],
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('除以'), findsOneWidget);
        final node = tester.getSemantics(find.bySemanticsLabel(copyLabel));
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(clipboardWrites, ['1234.5']);
        expect(find.text(copiedLabel), findsOneWidget);

        await tester.pumpWidget(
          _harness(
            const Display(current: 'Error', history: ''),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.bySemanticsLabel(errorLabel)),
          matchesSemantics(label: errorLabel),
        );
        expect(find.bySemanticsLabel(copyLabel), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
