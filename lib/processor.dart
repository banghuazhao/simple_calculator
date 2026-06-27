import 'dart:async';

import 'package:simple_calculator/calculator-key.dart';
import 'package:simple_calculator/key-controller.dart';
import 'package:simple_calculator/key-symbol.dart';

abstract class Processor {
  static KeySymbol? _operator;
  static String _valA = '0';
  static String? _valB;
  static String? _result;

  static StreamController _controller = StreamController();
  static Stream get _stream => _controller.stream;

  static StreamSubscription listen(Function(dynamic) handler) => _stream.listen(handler);
  static void refresh() => _fire(_output);

  static void _fire(String data) => _controller.add(_output);

  static String get _output => _result ?? _equation;

  static String get _equation =>
      _valA +
      (_operator != null ? ' ' + _operator!.value : '') +
      (_valB != null ? ' ' + _valB! : '');

  static dispose() => _controller.close();

  static process(dynamic event) {
    CalculatorKey key = (event as KeyEvent).key;
    switch (key.symbol.type) {
      case KeyType.FUNCTION:
        return handleFunction(key);

      case KeyType.OPERATOR:
        return handleOperator(key);

      case KeyType.INTEGER:
        return handleInteger(key);
    }
  }

  static void handleFunction(CalculatorKey key) {
    if (_result != null) {
      _condense();
    }

    Map<KeySymbol, dynamic> table = {
      Keys.clear: () => _clear(),
      Keys.sign: () => _sign(),
      Keys.percent: () => _percent(),
      Keys.decimal: () => _decimal(),
      Keys.back: () => _back(),
    };

    table[key.symbol]();
    refresh();
  }

  static void handleOperator(CalculatorKey key) {
    if (_valA == '.' || (_valB != null && _valB == '.')) {
      return;
    }
    if (key.symbol == Keys.equals) {
      return _calculate();
    }
    if (_valA != null && _valB != null) {
      _calculate();
    }

    if (_result != null) {
      _condense();
    }

    _operator = key.symbol;
    refresh();
  }

  static void handleInteger(CalculatorKey key) {
    String val = key.symbol.value;
    if (_result != null) {
      _condense();
    }

    if (_operator == null) {
      if (_valA.contains('.') && val == '.') {
        return;
      }
      _valA = (_valA == '0') ? val : _valA + val;
    } else {
      if (_valB != null && _valB!.contains('.') && val == '.') {
        return;
      }
      if (_valB != null) {
        _valB = (_valB == '0') ? val : _valB! + val;
      } else {
        _valB = val;
      }
    }
    if (_result != null) {
      print("_result: " + (_result ?? 'null'));
    }
    print("_equation: " + _equation);
    print("_output: " + _output);
    refresh();
  }

  static void _back() {
    if (_valB != null) {
      if (_valB!.length == 1) {
        _valB = null;
      } else {
        _valB = _valB!.substring(0, _valB!.length - 1);
      }
    } else if (_operator != null) {
      _operator = null;
    } else if (_valA != '0') {
      if (_valA.length == 1) {
        _valA = '0';
      } else {
        _valA = _valA.substring(0, _valA.length - 1);
      }
    }
  }

  static void _clear() {
    _valA = '0';
    _valB = null;
    _operator = _result = null;
  }

  static void _sign() {
    if (_valB != null) {
      _valB = (_valB!.contains('-') ? _valB!.substring(1) : '-' + _valB!);
    } else if (_valA != '0') {
      _valA = (_valA.contains('-') ? _valA.substring(1) : '-' + _valA);
    }
  }

  static String calcPercent(String x) => (double.parse(x) / 100).toString();

  static void _percent() {
    if (_valB != null) {
      _valB = calcPercent(_valB!);
    } else if (_valA != '0') {
      _valA = calcPercent(_valA);
    }
  }

  static void _decimal() {
    if (_valB != null && !_valB!.contains('.')) {
      _valB = _valB! + '.';
    } else if (_valA != '0' && !_valA.contains('.')) {
      _valA = _valA + '.';
    }
  }

  static void _calculate() {
    if (_operator == null || _valB == null) {
      return;
    }

    Map<KeySymbol, dynamic> table = {
      Keys.divide: (a, b) => (a / b),
      Keys.multiply: (a, b) => (a * b),
      Keys.subtract: (a, b) => (a - b),
      Keys.add: (a, b) => (a + b)
    };

    double result = table[_operator!](double.parse(_valA), double.parse(_valB!));
    String str = result.toString();

    while ((str.contains('.') && str.endsWith('0')) || str.endsWith('.')) {
      str = str.substring(0, str.length - 1);
    }

    _result = str;
    refresh();
  }

  static void _condense() {
    _valA = _result!;
    _valB = null;
    _result = _operator = null;
  }
}
