import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/scientific_page.dart';
import 'package:simple_calculator/util/theme_model.dart';

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
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ThemeModel(),
          child: const MaterialApp(
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: ScientificPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strings = S.of(tester.element(find.byType(ScientificPage)));
      final field = find.byType(TextField);
      final controller = tester.widget<TextField>(field).controller!;
      await tester.tap(find.widgetWithText(ActionChip, 'sin'));
      await tester.pumpAndSettle();
      expect(controller.text, 'sin()');
      expect(controller.selection.baseOffset, 4);

      await tester.enterText(field, 'sin(30)');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('0.5'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(ChoiceChip, strings.scientificRadians),
      );
      await tester.pumpAndSettle();
      expect(find.text('0.5'), findsNothing);
      await tester.enterText(field, 'sin(pi / 2)');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.enterText(field, 'sqrt(-1)');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text(strings.scientificInvalidExpression), findsOneWidget);
      expect(find.byTooltip(strings.copyResult), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
