import 'dart:math' as math;

/// Evaluates scientific expressions without changing the calculator's input
/// or history. Multiplication must be written explicitly, such as `2 * pi`.
class ExpressionEngine {
  static const maxLength = 512;

  static double evaluate(
    String expression, {
    Map<String, double> variables = const {},
    bool degrees = true,
  }) => _ExpressionParser(expression).parse()((
    variables: variables,
    degrees: degrees,
  ));

  /// Validates syntax and lists variable names in their first-use order.
  /// Names use ASCII letters, digits, and underscores and may not start with
  /// a digit. Names are case-sensitive. Functions and constants are reserved.
  static Set<String> variablesIn(String expression) {
    final parser = _ExpressionParser(expression);
    parser.parse();
    return Set.unmodifiable(parser.variables);
  }
}

typedef _Evaluation = ({Map<String, double> variables, bool degrees});
typedef _Expression = double Function(_Evaluation);
typedef _Operation = double Function(double, double);
typedef _ScientificFunction = double Function(double, bool);

class _ExpressionParser {
  _ExpressionParser(this._source);

  static const _maxNesting = 32;
  static final _whitespace = RegExp(r'\s*');
  static final _number = RegExp(
    r'(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?',
  );
  static final _name = RegExp(r'[A-Za-z_][A-Za-z_0-9]*|π');
  static const _constants = {'pi': math.pi, 'π': math.pi, 'e': math.e};
  static final _functions = <String, _ScientificFunction>{
    'sqrt': (value, _) => math.sqrt(value),
    'log': (value, _) => math.log(value) / math.ln10,
    'ln': (value, _) => math.log(value),
    'abs': (value, _) => value.abs(),
    'sin': (value, degrees) => math.sin(_toRadians(value, degrees)),
    'cos': (value, degrees) => math.cos(_toRadians(value, degrees)),
    'tan': _tangent,
  };

  final String _source;
  late final String _input = _source
      .replaceAll('−', '-')
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
  final Set<String> variables = {};
  int _offset = 0;

  _Expression parse() {
    if (_source.length > ExpressionEngine.maxLength) {
      throw const FormatException('Expression is too long');
    }
    final expression = _sum(0);
    _skipWhitespace();
    if (_offset != _input.length) _fail('Unexpected token');
    return expression;
  }

  _Expression _sum(int depth) {
    var left = _product(depth);
    while (true) {
      if (_take('+')) {
        left = _binary(left, _product(depth), (a, b) => a + b);
      } else if (_take('-')) {
        left = _binary(left, _product(depth), (a, b) => a - b);
      } else {
        return left;
      }
    }
  }

  _Expression _product(int depth) {
    var left = _unary(depth);
    while (true) {
      if (_take('*')) {
        left = _binary(left, _unary(depth), (a, b) => a * b);
      } else if (_take('/')) {
        left = _binary(left, _unary(depth), (a, b) => a / b);
      } else {
        return left;
      }
    }
  }

  _Expression _unary(int depth) {
    if (depth > _maxNesting) _fail('Expression is nested too deeply');
    if (_take('+')) return _unary(depth + 1);
    if (_take('-')) {
      final operand = _unary(depth + 1);
      return (evaluation) => -operand(evaluation);
    }
    final base = _primary(depth);
    return _take('^')
        ? _binary(base, _unary(depth + 1), (a, b) => math.pow(a, b).toDouble())
        : base;
  }

  _Expression _primary(int depth) {
    if (_take('(')) return _parenthesized(depth);

    final literal = _match(_number);
    if (literal != null) {
      final value = double.parse(literal);
      return (_) => _finite(value);
    }

    final name = _match(_name);
    if (name == null) _fail('Expected a number, name, or parenthesis');
    final lower = name.toLowerCase();
    final function = _functions[lower];
    if (_take('(')) {
      if (function == null) _fail('Unknown function');
      final argument = _parenthesized(depth);
      return (evaluation) =>
          _finite(function(argument(evaluation), evaluation.degrees));
    }
    if (function != null) _fail('Function requires parentheses');

    final constant = _constants[lower];
    if (constant != null) return (_) => constant;
    variables.add(name);
    return (evaluation) {
      final value = evaluation.variables[name];
      if (value == null) throw FormatException('Missing variable $name');
      return _finite(value);
    };
  }

  _Expression _parenthesized(int depth) {
    final expression = _sum(depth + 1);
    if (!_take(')')) _fail('Expected a closing parenthesis');
    return expression;
  }

  void _skipWhitespace() {
    _offset = _whitespace.matchAsPrefix(_input, _offset)!.end;
  }

  bool _take(String token) {
    _skipWhitespace();
    if (!_input.startsWith(token, _offset)) return false;
    _offset += token.length;
    return true;
  }

  String? _match(RegExp pattern) {
    _skipWhitespace();
    final match = pattern.matchAsPrefix(_input, _offset);
    if (match == null) return null;
    _offset = match.end;
    return match[0];
  }

  Never _fail(String message) =>
      throw FormatException(message, _source, _offset);
}

_Expression _binary(
  _Expression left,
  _Expression right,
  _Operation operation,
) =>
    (evaluation) => _finite(operation(left(evaluation), right(evaluation)));

double _finite(double value) {
  if (!value.isFinite) throw const FormatException('Expected a finite value');
  return value;
}

double _toRadians(double value, bool degrees) =>
    degrees ? value.remainder(360) * (math.pi / 180) : value;

double _tangent(double value, bool degrees) {
  final halfTurn = degrees ? 180.0 : math.pi;
  if (value % halfTurn == halfTurn / 2) {
    throw const FormatException('Tangent is undefined at this angle');
  }
  return math.tan(_toRadians(value, degrees));
}
