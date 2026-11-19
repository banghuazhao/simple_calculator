import 'package:simple_calculator/premium/expression_engine.dart';

/// The arithmetic supported by the history editor.
class HistoryExpression {
  static const maxLength = 384;
  static const _number =
      r'[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?';
  static final _numbers = RegExp(_number);
  static final _numericOperators = RegExp(r'^[0-9eE+×÷*/(). -]+$');
  static final _percent = RegExp('^($_number) *%\$');
  static final _binaryPercent = RegExp(
    '^($_number) *([+−×÷*/-]) *($_number) *%\$',
  );
  static final _whitespace = RegExp(r'\s+');

  static String fromEquation(String equation) => equation.endsWith(' =')
      ? equation.substring(0, equation.length - 2)
      : equation;

  static String normalize(String expression) =>
      expression.trim().replaceAll(_whitespace, ' ');

  static double percentOperand(
    double base,
    String operator,
    double percentage,
  ) {
    final fraction = percentage / 100;
    return switch (operator) {
      '+' || '-' || '−' => base * fraction,
      _ => fraction,
    };
  }

  static double evaluate(String expression) {
    if (expression.isEmpty || expression.length > maxLength) {
      throw const FormatException('Invalid history expression length');
    }
    final input = expression.replaceAll('−', '-');
    final binaryPercent = _binaryPercent.firstMatch(input);
    if (binaryPercent != null) {
      final base = _finite(double.parse(binaryPercent[1]!));
      final operator = binaryPercent[2]!;
      final percentage = _finite(double.parse(binaryPercent[3]!));
      final operand = _finite(percentOperand(base, operator, percentage));
      return ExpressionEngine.evaluate('$base $operator $operand');
    }
    final percent = _percent.firstMatch(input);
    if (percent != null) return _finite(double.parse(percent[1]!)) / 100;
    if (!_numericOperators.hasMatch(input)) {
      throw const FormatException('Expected an arithmetic expression');
    }
    // The scientific parser accepts variables and the constant e. Only allow
    // e/E as part of a number's exponent in a basic history expression.
    final nonNumbers = input.replaceAll(_numbers, '');
    if (nonNumbers.contains('e') || nonNumbers.contains('E')) {
      throw const FormatException('Expected a number');
    }
    return ExpressionEngine.evaluate(input);
  }

  static double _finite(double value) {
    if (!value.isFinite) throw const FormatException('Expected a finite value');
    return value;
  }
}
