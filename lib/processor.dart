import 'dart:async';

import 'package:simple_calculator/calculator-key.dart';
import 'package:simple_calculator/key-controller.dart';
import 'package:simple_calculator/key-symbol.dart';

/// Structured output emitted on every state change.
class CalcState {
  final String current; // main large display
  final String history; // small equation line above (empty when not applicable)
  final bool isResult; // true when showing a freshly computed result

  const CalcState({
    required this.current,
    required this.history,
    this.isResult = false,
  });
}

abstract class Processor {
  static KeySymbol? _operator;
  static String _valA = '0';
  static String? _valB;
  static String? _result;

  static final StreamController<CalcState> _controller =
      StreamController<CalcState>.broadcast();

  static StreamSubscription<CalcState> listen(void Function(CalcState) handler) =>
      _controller.stream.listen(handler);

  static void refresh() => _controller.add(_calcState);

  static CalcState get _calcState {
    if (_result != null) {
      if (_result == 'Error') {
        return const CalcState(current: 'Error', history: '', isResult: true);
      }
      return CalcState(
        current: _result!,
        history: '$_valA ${_operator!.value} $_valB =',
        isResult: true,
      );
    }
    if (_operator != null) {
      return CalcState(
        current: _valB ?? _valA,
        history: '$_valA ${_operator!.value}',
      );
    }
    return CalcState(current: _valA, history: '');
  }

  static void dispose() => _controller.close();

  static void process(dynamic event) {
    final CalculatorKey key = (event as KeyEvent).key;
    switch (key.symbol.type) {
      case KeyType.FUNCTION:
        return _handleFunction(key);
      case KeyType.OPERATOR:
        return _handleOperator(key);
      case KeyType.INTEGER:
        return _handleInteger(key);
    }
  }

  static void _handleFunction(CalculatorKey key) {
    if (_result != null) _condense();

    switch (key.symbol) {
      case Keys.clear:
        _clear();
        break;
      case Keys.sign:
        _sign();
        break;
      case Keys.percent:
        _percent();
        break;
      case Keys.back:
        _back();
        break;
    }
    refresh();
  }

  static void _handleOperator(CalculatorKey key) {
    // Don't operate on a bare decimal input
    if (_valA == '0.' || (_valB != null && _valB == '0.')) return;

    if (key.symbol == Keys.equals) {
      return _calculate();
    }
    // Chain operations: evaluate pending before setting next operator
    if (_valB != null) _calculate();
    if (_result != null) _condense();

    _operator = key.symbol;
    refresh();
  }

  static void _handleInteger(CalculatorKey key) {
    final String val = key.symbol.value;
    if (_result != null) _condense();

    if (_operator == null) {
      if (val == '.') {
        if (!_valA.contains('.')) _valA += '.';
      } else {
        if (_countDigits(_valA) >= 9) return; // digit limit
        _valA = (_valA == '0') ? val : _valA + val;
      }
    } else {
      if (_valB == null) {
        _valB = val == '.' ? '0.' : val;
      } else {
        if (val == '.') {
          if (!_valB!.contains('.')) _valB = _valB! + '.';
        } else {
          if (_countDigits(_valB!) >= 9) return; // digit limit
          _valB = (_valB == '0') ? val : _valB! + val;
        }
      }
    }
    refresh();
  }

  static int _countDigits(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), '').length;

  static void _back() {
    if (_result != null) {
      _clear();
      return;
    }
    if (_valB != null) {
      _valB = _valB!.length == 1 ? null : _valB!.substring(0, _valB!.length - 1);
    } else if (_operator != null) {
      _operator = null;
    } else if (_valA != '0') {
      _valA = _valA.length == 1 ? '0' : _valA.substring(0, _valA.length - 1);
    }
  }

  static void _clear() {
    _valA = '0';
    _valB = null;
    _operator = _result = null;
  }

  static void _sign() {
    if (_valB != null) {
      _valB = _valB!.startsWith('-') ? _valB!.substring(1) : '-$_valB';
    } else if (_valA != '0') {
      _valA = _valA.startsWith('-') ? _valA.substring(1) : '-$_valA';
    }
  }

  static void _percent() {
    if (_valB != null) {
      _valB = _formatResult(double.parse(_valB!) / 100);
    } else if (_valA != '0') {
      _valA = _formatResult(double.parse(_valA) / 100);
    }
  }

  static void _calculate() {
    if (_operator == null || _valB == null) return;

    final double a = double.parse(_valA);
    final double b = double.parse(_valB!);

    if (_operator == Keys.divide && b == 0) {
      _result = 'Error';
      refresh();
      return;
    }

    double result;
    if (_operator == Keys.divide) {
      result = a / b;
    } else if (_operator == Keys.multiply) {
      result = a * b;
    } else if (_operator == Keys.subtract) {
      result = a - b;
    } else {
      result = a + b;
    }

    _result = _formatResult(result);
    refresh();
  }

  static String _formatResult(double value) {
    String str = value.toString();
    // Remove trailing zeros after decimal point
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str.isEmpty ? '0' : str;
  }

  static void _condense() {
    if (_result == 'Error') {
      _clear();
      return;
    }
    _valA = _result!;
    _valB = null;
    _result = _operator = null;
  }
}
