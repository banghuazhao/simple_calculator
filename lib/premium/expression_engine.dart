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

  /// Validates syntax once so the same expression can be evaluated repeatedly.
  static CompiledExpression compile(String expression) {
    final parser = _ExpressionParser(expression);
    final evaluate = parser.parse();
    return CompiledExpression._(evaluate, Set.unmodifiable(parser.variables));
  }

  /// Validates syntax and lists variable names in their first-use order.
  /// Names use ASCII letters, digits, and underscores and may not start with
  /// a digit. Names are case-sensitive. Constants and the original unary
  /// functions are reserved. New function names can still be used as variables
  /// in saved formulas when written without parentheses.
  static Set<String> variablesIn(String expression) =>
      compile(expression).variables;
}

enum ExpressionError {
  syntax,
  missingClosingParenthesis,
  unknownFunction,
  missingVariable,
  divideByZero,
  domain,
  overflow,
  tooLong,
  tooDeep,
}

/// A localized interface can describe [kind] and highlight [offset] in [source].
class ExpressionException extends FormatException {
  const ExpressionException(
    this.kind,
    String message, {
    String? source,
    int? offset,
    this.identifier,
  }) : super(message, source, offset);

  final ExpressionError kind;
  final String? identifier;
}

class CompiledExpression {
  const CompiledExpression._(this._evaluate, this.variables);

  final _Expression _evaluate;
  final Set<String> variables;

  double evaluate({
    Map<String, double> variables = const {},
    bool degrees = true,
  }) => _evaluate((variables: variables, degrees: degrees));
}

typedef _Evaluation = ({Map<String, double> variables, bool degrees});
typedef _Expression = double Function(_Evaluation);
typedef _Operation = double Function(double, double);
typedef _ScientificFunction = double Function(double, bool);
typedef _UnaryOperation = double Function(double);

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
    'log': (value, _) => _log(value) / math.ln10,
    'ln': (value, _) => _log(value),
    'abs': (value, _) => value.abs(),
    'sin': (value, degrees) => math.sin(_toRadians(value, degrees)),
    'cos': (value, degrees) => math.cos(_toRadians(value, degrees)),
    'tan': _tangent,
  };
  static final _additionalFunctions = <String, _ScientificFunction>{
    'asin': (value, degrees) => _fromRadians(math.asin(value), degrees),
    'acos': (value, degrees) => _fromRadians(math.acos(value), degrees),
    'atan': (value, degrees) => _fromRadians(math.atan(value), degrees),
  };
  static const _pairFunctions = <String, _Operation>{
    'ncr': _combinations,
    'npr': _permutations,
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
      _fail(
        'Expression is too long',
        kind: ExpressionError.tooLong,
        offset: ExpressionEngine.maxLength,
      );
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
        final offset = _offset - 1;
        left = _binary(left, _product(depth), (a, b) => a + b, offset);
      } else if (_take('-')) {
        final offset = _offset - 1;
        left = _binary(left, _product(depth), (a, b) => a - b, offset);
      } else {
        return left;
      }
    }
  }

  _Expression _product(int depth) {
    var left = _unary(depth);
    while (true) {
      if (_take('*')) {
        final offset = _offset - 1;
        left = _binary(left, _unary(depth), (a, b) => a * b, offset);
      } else if (_take('/')) {
        final offset = _offset - 1;
        left = _binary(left, _unary(depth), _divide, offset);
      } else {
        return left;
      }
    }
  }

  _Expression _unary(int depth) {
    if (depth > _maxNesting) {
      _fail('Expression is nested too deeply', kind: ExpressionError.tooDeep);
    }
    if (_take('+')) return _unary(depth + 1);
    if (_take('-')) {
      final operand = _unary(depth + 1);
      return (evaluation) => -operand(evaluation);
    }
    final primary = _primary(depth);
    final base = _take('!')
        ? _apply(primary, _factorial, _offset - 1)
        : primary;
    if (!_take('^')) return base;
    final offset = _offset - 1;
    return _binary(base, _unary(depth + 1), _power, offset);
  }

  _Expression _primary(int depth) {
    if (_take('(')) return _parenthesized(depth);

    final literal = _match(_number);
    if (literal != null) {
      final value = double.parse(literal);
      return _checked(_offset - literal.length, (_) => value);
    }

    final name = _match(_name);
    if (name == null) _fail('Expected a number, name, or parenthesis');
    final lower = name.toLowerCase();
    final nameOffset = _offset - name.length;
    final originalFunction = _functions[lower];
    if (_take('(')) {
      final function = originalFunction ?? _additionalFunctions[lower];
      final pairFunction = _pairFunctions[lower];
      if (function != null) {
        final argument = _parenthesized(depth);
        return _checked(
          nameOffset,
          (evaluation) => function(argument(evaluation), evaluation.degrees),
        );
      }
      if (pairFunction != null) {
        final first = _sum(depth + 1);
        if (!_take(',')) _fail('Expected a comma between arguments');
        final second = _parenthesized(depth);
        return _binary(first, second, pairFunction, nameOffset);
      }
      _fail(
        'Unknown function',
        kind: ExpressionError.unknownFunction,
        offset: nameOffset,
        identifier: name,
      );
    }
    if (originalFunction != null) _fail('Function requires parentheses');

    final constant = _constants[lower];
    if (constant != null) return (_) => constant;
    variables.add(name);
    return _checked(nameOffset, (evaluation) {
      final value = evaluation.variables[name];
      if (value == null) {
        _fail(
          'Missing variable $name',
          kind: ExpressionError.missingVariable,
          offset: nameOffset,
          identifier: name,
        );
      }
      return value;
    });
  }

  _Expression _parenthesized(int depth) {
    final expression = _sum(depth + 1);
    if (!_take(')')) {
      _fail(
        'Expected a closing parenthesis',
        kind: ExpressionError.missingClosingParenthesis,
      );
    }
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

  _Expression _apply(
    _Expression operand,
    _UnaryOperation operation,
    int offset,
  ) => _checked(offset, (evaluation) => operation(operand(evaluation)));

  _Expression _binary(
    _Expression left,
    _Expression right,
    _Operation operation,
    int offset,
  ) => _checked(
    offset,
    (evaluation) => operation(left(evaluation), right(evaluation)),
  );

  _Expression _checked(int offset, _Expression evaluate) => (evaluation) {
    final double value;
    try {
      value = evaluate(evaluation);
    } on ExpressionException catch (error) {
      if (error.offset != null) rethrow;
      _fail(
        error.message,
        kind: error.kind,
        offset: offset,
        identifier: error.identifier,
      );
    }
    if (!value.isFinite) {
      _fail(
        value.isNaN
            ? 'Value is outside the operation’s domain'
            : 'Value is outside the supported numeric range',
        kind: value.isNaN ? ExpressionError.domain : ExpressionError.overflow,
        offset: offset,
      );
    }
    return value;
  };

  Never _fail(
    String message, {
    ExpressionError kind = ExpressionError.syntax,
    int? offset,
    String? identifier,
  }) => throw ExpressionException(
    kind,
    message,
    source: _source,
    offset: offset ?? _offset,
    identifier: identifier,
  );
}

const _divisionByZero = ExpressionException(
  ExpressionError.divideByZero,
  'Cannot divide by zero',
);
const _combinatoricDomain = ExpressionException(
  ExpressionError.domain,
  'Expected whole numbers with 0 ≤ r ≤ n',
);
const _combinatoricOverflow = ExpressionException(
  ExpressionError.overflow,
  'Result is outside the supported numeric range',
);

double _divide(double left, double right) {
  if (right == 0) throw _divisionByZero;
  return left / right;
}

double _power(double base, double exponent) {
  if (base == 0 && exponent < 0) throw _divisionByZero;
  return math.pow(base, exponent).toDouble();
}

double _log(double value) {
  if (value <= 0) {
    throw const ExpressionException(
      ExpressionError.domain,
      'A logarithm requires a positive value',
    );
  }
  return math.log(value);
}

bool _isNonNegativeInteger(double value) =>
    value >= 0 && value.isFinite && value.truncateToDouble() == value;

double _factorial(double value) {
  if (!_isNonNegativeInteger(value)) {
    throw const ExpressionException(
      ExpressionError.domain,
      'A factorial requires a non-negative whole number',
    );
  }
  if (value > 170) throw _combinatoricOverflow;
  final n = BigInt.from(value);
  return _descendingProduct(n, n);
}

(BigInt, BigInt) _combinatoricInputs(double n, double r) {
  if (!_isNonNegativeInteger(n) || !_isNonNegativeInteger(r) || r > n) {
    throw _combinatoricDomain;
  }
  return (BigInt.from(n), BigInt.from(r));
}

double _combinations(double n, double r) {
  final (total, selected) = _combinatoricInputs(n, r);
  final unselected = total - selected;
  final count = selected < unselected ? selected : unselected;
  final start = total - count;
  var result = BigInt.one;
  for (var i = BigInt.one; i <= count; i += BigInt.one) {
    result = result * (start + i) ~/ i;
    // The product grows each step. Bound work before converting to double.
    if (result.bitLength > 1024) throw _combinatoricOverflow;
  }
  return result.toDouble();
}

double _permutations(double n, double r) {
  final (total, selected) = _combinatoricInputs(n, r);
  return _descendingProduct(total, selected);
}

double _descendingProduct(BigInt start, BigInt count) {
  final stop = start - count;
  var result = BigInt.one;
  for (var factor = start; factor > stop; factor -= BigInt.one) {
    result *= factor;
    if (result.bitLength > 1024) throw _combinatoricOverflow;
  }
  return result.toDouble();
}

double _toRadians(double value, bool degrees) =>
    degrees ? value.remainder(360) * (math.pi / 180) : value;

double _fromRadians(double value, bool degrees) =>
    degrees ? value * (180 / math.pi) : value;

double _tangent(double value, bool degrees) {
  final halfTurn = degrees ? 180.0 : math.pi;
  if (value % halfTurn == halfTurn / 2) {
    throw const ExpressionException(
      ExpressionError.domain,
      'Tangent is undefined at this angle',
    );
  }
  return math.tan(_toRadians(value, degrees));
}
