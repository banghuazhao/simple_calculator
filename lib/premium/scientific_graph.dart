import 'dart:math' as math;

import 'package:simple_calculator/premium/expression_engine.dart';

typedef GraphPoint = ({double x, double? y});
typedef GraphRoot = ({double x, double y});

enum GraphRootStatus { found, needsBracket, unverified }

typedef GraphRootResult = ({GraphRootStatus status, GraphRoot? root});

class GraphInterval {
  const GraphInterval._(this.minimum, this.maximum);

  final double minimum;
  final double maximum;

  double get width => maximum - minimum;

  static GraphInterval? tryCreate(double? minimum, double? maximum) {
    if (minimum == null ||
        maximum == null ||
        !minimum.isFinite ||
        !maximum.isFinite ||
        minimum >= maximum ||
        !(maximum - minimum).isFinite) {
      return null;
    }
    return GraphInterval._(minimum, maximum);
  }

  double position(double fraction) => fraction == 1
      ? maximum
      : (minimum + width * fraction).clamp(minimum, maximum);
}

/// Graphs bind x and, when available, the scientific workspace's previous
/// result. Formula variables keep their original case in the shared parser.
class GraphVariablesException implements Exception {
  const GraphVariablesException();
}

class ScientificGraph {
  ScientificGraph._(
    this._expression,
    this._degrees,
    this._answer,
    this._xNames,
  );

  final CompiledExpression _expression;
  final bool _degrees;
  final Map<String, double> _answer;
  final List<String> _xNames;

  factory ScientificGraph.compile(
    String source, {
    required bool degrees,
    double? answer,
  }) {
    final compiled = ExpressionEngine.compile(source);
    final names = <String>[];
    final bindings = <String, double>{};
    for (final name in compiled.variables) {
      switch (name.toLowerCase()) {
        case 'x':
          names.add(name);
        case 'ans' when answer != null && answer.isFinite:
          bindings[name] = answer;
        default:
          throw const GraphVariablesException();
      }
    }
    return ScientificGraph._(compiled, degrees, bindings, names);
  }

  double? valueAt(double x) {
    try {
      final result = _expression.evaluate(
        degrees: _degrees,
        variables: {..._answer, for (final name in _xNames) name: x},
      );
      return result.isFinite ? result : null;
    } on FormatException {
      return null;
    }
  }

  GraphPoint _pointAt(double x) => (x: x, y: valueAt(x));

  List<GraphPoint> curve(GraphInterval interval) {
    const steps = 240;
    final samples = <GraphPoint>[_pointAt(interval.minimum)];
    for (var i = 1; i <= steps; i++) {
      final next = _pointAt(interval.position(i / steps));
      final previous = samples.last;
      if (previous.x == next.x) continue;
      final left = previous.y;
      final right = next.y;
      if (left != null && right != null) {
        final middle = _pointAt(previous.x + (next.x - previous.x) / 2);
        if (middle.x != previous.x &&
            middle.x != next.x &&
            _suspectGap(left, middle.y, right)) {
          samples.add((x: middle.x, y: null));
        }
      }
      samples.add(next);
    }
    return samples;
  }

  List<GraphPoint> valueTable(GraphInterval interval) {
    const steps = 10;
    final points = <GraphPoint>[];
    for (var index = 0; index <= steps; index++) {
      final x = interval.position(index / steps);
      if (points.isEmpty || points.last.x != x) points.add(_pointAt(x));
    }
    return points;
  }

  bool _suspectGap(double left, double? middle, double right) {
    if (middle == null) return true;
    final crossesZero = left != 0 && right != 0 && left.sign != right.sign;
    if (crossesZero && (middle == left || middle == right)) return true;
    if (middle >= math.min(left, right) && middle <= math.max(left, right)) {
      return false;
    }
    if (crossesZero) {
      final sameSide = middle.isNegative == left.isNegative ? left : right;
      return middle.abs() > sameSide.abs() * 1.1;
    }
    return middle.abs() / math.max(left.abs(), right.abs()) > 2;
  }

  GraphRootResult findRoot(GraphInterval interval) {
    var left = interval.minimum;
    var right = interval.maximum;
    var low = valueAt(left);
    var high = valueAt(right);
    const needsBracket = (status: GraphRootStatus.needsBracket, root: null);
    const unverified = (status: GraphRootStatus.unverified, root: null);
    if (low == 0) return _root(left, low!);
    if (high == 0) return _root(right, high!);
    if (low == null || high == null || low.isNegative == high.isNegative) {
      return needsBracket;
    }

    final initialLow = low.abs();
    final initialHigh = high.abs();
    // A bracket can span nearly the entire binary64 exponent range.
    for (var i = 0; i < 2100; i++) {
      final middle = left + (right - left) / 2;
      if (middle == left || middle == right) break;
      final value = valueAt(middle);
      if (value == null) return unverified;
      if (value == 0) return _root(middle, value);
      if (value.isNegative == low!.isNegative) {
        left = middle;
        low = value;
      } else {
        right = middle;
        high = value;
      }
    }

    // A sign change can also mark a jump or pole. For an approximate root,
    // require the bracket and the residual on each side to shrink. Ratios
    // keep this test meaningful even if the function is very small or large.
    if ((right - left) / interval.width > 1e-10 ||
        low!.abs() / initialLow > 1e-8 ||
        high!.abs() / initialHigh > 1e-8) {
      return unverified;
    }
    return low.abs() <= high.abs() ? _root(left, low) : _root(right, high);
  }

  GraphRootResult _root(double x, double y) =>
      (status: GraphRootStatus.found, root: (x: x, y: y));
}
