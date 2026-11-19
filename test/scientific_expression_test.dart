import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/scientific_graph_page.dart';
import 'package:simple_calculator/premium/scientific_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

Widget _scientificApp([Widget home = const ScientificPage()]) {
  return ChangeNotifierProvider(
    create: (_) => ThemeModel(),
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: home,
    ),
  );
}

String? _result(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText)).data;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterCalculation(WidgetTester tester, String source) async {
  final field = find.byType(TextField);
  await tester.ensureVisible(field);
  await tester.enterText(field, source);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  group('scientific expression engine', () {
    test('resolves precedence, powers, and unary signs', () {
      const cases = {
        '2 + 3 × 4': 14,
        '(2 + 3) * 4': 20,
        '12 ÷ 3 / 2': 2,
        '9 - 4 − 3': 2,
        '2^3^2': 512,
        '−2^2': -4,
        '(-2)^2': 4,
        '2^-2': 0.25,
        '2--3': 5,
        '.5 + 1.e-1': 0.6,
      };
      for (final entry in cases.entries) {
        expect(
          ExpressionEngine.evaluate(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('handles functions, constants, and both angle units', () {
      expect(ExpressionEngine.evaluate('sqrt(9) + abs(-4)'), 7);
      expect(ExpressionEngine.evaluate('LOG(100) + ln(e)'), closeTo(3, 1e-12));
      expect(ExpressionEngine.evaluate('π + PI'), 2 * math.pi);
      expect(ExpressionEngine.evaluate('sin(30)'), closeTo(0.5, 1e-12));
      expect(ExpressionEngine.evaluate('cos(180)'), closeTo(-1, 1e-12));
      expect(ExpressionEngine.evaluate('tan(45)'), closeTo(1, 1e-12));
      expect(ExpressionEngine.evaluate('sin(π / 2)', degrees: false), 1);
      expect(ExpressionEngine.evaluate('sin(360)'), 0);
    });

    test('discovers named variables without evaluating the expression', () {
      const formula = 'sqrt(y) / x + Rate * x + rate + 1 / 0';
      expect(
        ExpressionEngine.variablesIn(formula),
        orderedEquals(['y', 'x', 'Rate', 'rate']),
      );
      expect(ExpressionEngine.variablesIn('sin(PI / 2) + e'), isEmpty);
      expect(
        ExpressionEngine.evaluate(
          'Rate * quantity + rate',
          variables: {'Rate': 4, 'quantity': 3, 'rate': 1},
        ),
        13,
      );
      expect(() => ExpressionEngine.variablesIn('x +'), throwsFormatException);
      expect(() => ExpressionEngine.evaluate('x'), throwsFormatException);
      expect(
        () => ExpressionEngine.evaluate('x', variables: {'x': double.nan}),
        throwsFormatException,
      );
    });

    test(
      'rejects malformed, implicit, unbounded, and non-finite expressions',
      () {
        for (final expression in [
          '',
          '2(3)',
          '2pi',
          '3 +',
          '(1 + 2',
          'sin 30',
          'f(2)',
          '1e',
          '1,000',
          '1e309',
          '1e308 * 10',
          '1 / 0',
          'sqrt(-1)',
          'ln(0)',
          'tan(-90)',
          '${'(' * 33}1${')' * 33}',
          '1${'+1' * ExpressionEngine.maxLength}',
        ]) {
          expect(
            () => ExpressionEngine.evaluate(expression),
            throwsFormatException,
            reason: expression,
          );
        }
        expect(
          () => ExpressionEngine.evaluate('tan(pi / 2)', degrees: false),
          throwsFormatException,
        );
        expect(ExpressionEngine.evaluate('1${'+1' * 255}'), 256);
        expect(
          ExpressionEngine.evaluate('1.7976931348623157e308'),
          double.maxFinite,
        );
      },
    );
  });

  testWidgets(
    'scientific editor inserts functions and recalculates by angle unit',
    (tester) async {
      await tester.pumpWidget(_scientificApp());
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(find.byType(ScientificPage)));
      final field = find.byType(TextField);
      final controller = tester.widget<TextField>(field).controller!;
      await _tap(tester, find.widgetWithText(ActionChip, 'sin'));
      expect(controller.text, 'sin()');
      expect(controller.selection.baseOffset, 4);

      await _enterCalculation(tester, 'sin(30)');
      expect(_result(tester), '0.5');

      await _tap(
        tester,
        find.widgetWithText(ChoiceChip, strings.scientificRadians),
      );
      expect(find.byType(SelectableText), findsNothing);
      await _enterCalculation(tester, 'sin(pi / 2)');
      expect(_result(tester), '1');

      await _enterCalculation(tester, '2 + sqrt(-1)');
      expect(
        find.textContaining(strings.scientificDomainError),
        findsOneWidget,
      );
      expect(controller.selection.baseOffset, 4);
      expect(find.byTooltip(strings.copyResult), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'phone keypad supports exponent entry, full-precision Ans, and ENG',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_scientificApp());
      await tester.pumpAndSettle();

      Future<void> press(String key) =>
          _tap(tester, find.widgetWithText(TextButton, key));

      for (final key in ['1', 'EXP', '−', '3', '=']) {
        await press(key);
      }
      expect(_result(tester), '0.001');
      await _tap(tester, find.widgetWithText(FilterChip, 'ENG'));
      expect(_result(tester), '1e-3');
      await _tap(tester, find.widgetWithText(FilterChip, 'ENG'));

      await _enterCalculation(tester, '1 / 3');
      expect(_result(tester), '0.333333333333333');
      await _tap(tester, find.byTooltip('Clear input'));
      for (final key in ['Ans', '×', '3', '=']) {
        await press(key);
      }
      expect(_result(tester), '1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'history restores the original Ans and angle mode and reuses the result',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await StorageManager.init();
      final updates = <CalcState>[];
      final subscription = Processor.listen(updates.add);
      addTearDown(subscription.cancel);
      await tester.pumpWidget(
        _scientificApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const ScientificPage()),
                ),
                child: const Text('Open scientific'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final open = find.text('Open scientific');
      await _tap(tester, open);
      final radians = find.widgetWithText(ChoiceChip, 'Radians');
      await _tap(tester, radians);
      await _enterCalculation(tester, '1 / 3');
      await _enterCalculation(tester, 'Ans * 3');
      expect(_result(tester), '1');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tap(tester, open);
      expect(tester.widget<ChoiceChip>(radians).selected, isTrue);

      await _tap(tester, find.widgetWithText(ChoiceChip, 'Degrees'));
      await _enterCalculation(tester, '42');
      await _tap(tester, find.byTooltip('Scientific history'));
      await _tap(tester, find.text('Ans * 3'));
      expect(tester.widget<ChoiceChip>(radians).selected, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Ans * 3',
      );
      await _enterCalculation(tester, 'Ans * 6');
      expect(_result(tester), '2');
      await _tap(tester, find.text('Use this result'));
      expect(open, findsOneWidget);
      expect(updates.last.current, '2');
    },
  );

  testWidgets('graph receives the current expression, angle mode, and answer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ThemeModel.kHighContrastEnabled: true,
    });
    await StorageManager.init();
    await tester.binding.setSurfaceSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_scientificApp());
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).keyboardType, TextInputType.none);
    await _tap(tester, find.byTooltip('Show system keyboard'));
    expect(
      tester.widget<TextField>(field).keyboardType,
      TextInputType.multiline,
    );
    await _enterCalculation(tester, '1 / 3');
    await _tap(tester, find.widgetWithText(ChoiceChip, 'Radians'));
    await tester.enterText(field, 'sin(x) + Ans');
    await _tap(tester, find.byTooltip('Graph'));

    final graph = tester.widget<ScientificGraphPage>(
      find.byType(ScientificGraphPage),
    );
    expect(graph.initialExpression, 'sin(x) + Ans');
    expect(graph.degrees, isFalse);
    expect(graph.answer, 1 / 3);
    final plot = find.byKey(const ValueKey('scientific-graph-plot'));
    await tester.scrollUntilVisible(
      plot,
      180,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(plot, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
