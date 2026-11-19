import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/premium/expression_engine.dart';

void main() {
  test('inverse trig returns angles in the selected mode', () {
    expect(ExpressionEngine.evaluate('asin(0.5)'), closeTo(30, 1e-12));
    expect(ExpressionEngine.evaluate('ACOS(0.5)'), closeTo(60, 1e-12));
    expect(ExpressionEngine.evaluate('atan(-1)'), closeTo(-45, 1e-12));
    expect(
      ExpressionEngine.evaluate('asin(1) + acos(0)', degrees: false),
      math.pi,
    );
    expect(
      ExpressionEngine.evaluate('atan(1)', degrees: false),
      closeTo(math.pi / 4, 1e-12),
    );
    expect(ExpressionEngine.evaluate('sin(asin(0.5))'), closeTo(0.5, 1e-12));
  });

  test('factorial binds tighter than powers and signs', () {
    const cases = {
      '0!': 1,
      '(2 + 3)!': 120,
      '-3!': -6,
      '2^3!': 64,
      '3!^2': 36,
      '2^-3!': 0.015625,
      '(3!)!': 720,
    };
    for (final entry in cases.entries) {
      expect(
        ExpressionEngine.evaluate(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
    expect(
      ExpressionEngine.evaluate('170!'),
      closeTo(7.257415615307999e306, 1e292),
    );
    expect(() => ExpressionEngine.evaluate('3!!'), throwsFormatException);
  });

  test('combinations and permutations use exact integer intermediates', () {
    expect(ExpressionEngine.evaluate('nCr(5, 2)'), 10);
    expect(ExpressionEngine.evaluate('nPr(5, 2)'), 20);
    expect(ExpressionEngine.evaluate('NCR(2 + 3, nPr(2, 1))'), 10);
    expect(ExpressionEngine.evaluate('nCr(60, 30)'), 118264581564861424.0);
    expect(ExpressionEngine.evaluate('nCr(1e200, 1)'), 1e200);
    expect(ExpressionEngine.evaluate('nCr(1e200, 1e200)'), 1);
    expect(ExpressionEngine.evaluate('nPr(1e200, 0)'), 1);
    expect(
      () => ExpressionEngine.evaluate('nCr(5, 2, 1)'),
      throwsFormatException,
    );
    expect(() => ExpressionEngine.evaluate('nPr(5)'), throwsFormatException);
  });

  test('new function names remain usable as saved formula variables', () {
    final formula = ExpressionEngine.compile('asin + nCr + Ans + asin(0)');
    expect(formula.variables, orderedEquals(['asin', 'nCr', 'Ans']));
    expect(formula.evaluate(variables: {'asin': 1, 'nCr': 2, 'Ans': 3}), 6);
    expect(() => ExpressionEngine.variablesIn('sqrt'), throwsFormatException);
  });

  test(
    'reports operation categories and positions to the scientific editor',
    () {
      final cases = {
        '2 +': (ExpressionError.syntax, 3, null),
        '(2 + 3': (ExpressionError.missingClosingParenthesis, 6, null),
        '2 + F(1)': (ExpressionError.unknownFunction, 4, 'F'),
        '2 + Ans': (ExpressionError.missingVariable, 4, 'Ans'),
        '3 + 1 ÷ 0': (ExpressionError.divideByZero, 6, null),
        '2 + sqrt(-1)': (ExpressionError.domain, 4, null),
        '2 + asin(2)': (ExpressionError.domain, 4, null),
        '2 + ln(0)': (ExpressionError.domain, 4, null),
        '2 + tan(90)': (ExpressionError.domain, 4, null),
        '(-1)!': (ExpressionError.domain, 4, null),
        '1.5!': (ExpressionError.domain, 3, null),
        '171!': (ExpressionError.overflow, 3, null),
        'nCr(5, -1)': (ExpressionError.domain, 0, null),
        'nPr(2, 3)': (ExpressionError.domain, 0, null),
        'nCr(5, 2.5)': (ExpressionError.domain, 0, null),
        'nCr(1e200, 1e199)': (ExpressionError.overflow, 0, null),
        'nPr(1e200, 1e199)': (ExpressionError.overflow, 0, null),
        '1e308 × 10': (ExpressionError.overflow, 6, null),
      };
      for (final MapEntry(key: expression, value: (kind, offset, identifier))
          in cases.entries) {
        expect(
          () => ExpressionEngine.evaluate(expression),
          throwsA(
            isA<ExpressionException>()
                .having((error) => error.kind, 'kind', kind)
                .having((error) => error.source, 'source', expression)
                .having((error) => error.offset, 'offset', offset)
                .having((error) => error.identifier, 'identifier', identifier),
          ),
          reason: expression,
        );
      }
    },
  );
}
