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

/// A single completed calculation kept in the history log.
class HistoryEntry {
  final int id;
  final String equation; // e.g. "3 + 4 ="
  final String result;   // raw value without formatting
  const HistoryEntry({
    required this.id,
    required this.equation,
    required this.result,
  });
}

class _Snapshot {
  final String valA;
  final String? valB;
  final KeySymbol? op;
  final String? result;
  const _Snapshot(this.valA, this.valB, this.op, this.result);
}

abstract class Processor {
  static KeySymbol? _operator;
  static String _valA = '0';
  static String? _valB;
  static String? _result;

  static final List<HistoryEntry> _history = [];
  static final List<_Snapshot> _undoStack = [];
  static int _historyIdSeq = 0;

  static final StreamController<CalcState> _controller =
      StreamController<CalcState>.broadcast();

  static StreamSubscription<CalcState> listen(void Function(CalcState) handler) =>
      _controller.stream.listen(handler);

  static void refresh() => _controller.add(_calcState);

  /// All completed calculations, newest first.
  static List<HistoryEntry> get historyLog => List.unmodifiable(_history);

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

  // ── Undo ─────────────────────────────────────────────────────────────────

  static void _pushUndo() {
    _undoStack.add(_Snapshot(_valA, _valB, _operator, _result));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  static void undo() {
    if (_undoStack.isEmpty) return;
    final s = _undoStack.removeLast();
    _valA = s.valA;
    _valB = s.valB;
    _operator = s.op;
    _result = s.result;
    refresh();
  }

  // ── History ───────────────────────────────────────────────────────────────

  static void clearHistory() => _history.clear();

  static void removeHistoryEntry(int id) =>
      _history.removeWhere((e) => e.id == id);

  /// Load a history result back into the calculator as the current value.
  static void setFromHistory(String result) {
    _pushUndo();
    _clear();
    _valA = result;
    refresh();
  }

  // ── Key processing ────────────────────────────────────────────────────────

  static void process(dynamic event) {
    _pushUndo();
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
    if (_valA == '0.' || (_valB != null && _valB == '0.')) return;

    if (key.symbol == Keys.equals) {
      return _calculate();
    }
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
        if (_countDigits(_valA) >= 9) return;
        _valA = (_valA == '0') ? val : _valA + val;
      }
    } else {
      if (_valB == null) {
        _valB = val == '.' ? '0.' : val;
      } else {
        if (val == '.') {
          if (!_valB!.contains('.')) _valB = _valB! + '.';
        } else {
          if (_countDigits(_valB!) >= 9) return;
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

    _history.insert(0, HistoryEntry(
      id: _historyIdSeq++,
      equation: '$_valA ${_operator!.value} $_valB =',
      result: _result!,
    ));
    if (_history.length > 100) _history.removeLast();

    refresh();
  }

  static String _formatResult(double value) {
    String str = value.toString();
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
