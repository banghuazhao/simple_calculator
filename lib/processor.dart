import 'dart:async';

import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/history_storage.dart';

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
  final String result; // raw value without formatting
  const HistoryEntry({
    required this.id,
    required this.equation,
    required this.result,
  });
}

/// A removed history entry and where it was, so deletion can be undone.
class HistoryDeletion {
  final HistoryEntry entry;
  final int index;
  const HistoryDeletion._(this.entry, this.index);
}

class _Snapshot {
  final String valA;
  final String? valB;
  final KeySymbol? op;
  final String? result;
  const _Snapshot(this.valA, this.valB, this.op, this.result);

  bool matches(_Snapshot other) =>
      valA == other.valA &&
      valB == other.valB &&
      op == other.op &&
      result == other.result;
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

  static StreamSubscription<CalcState> listen(
    void Function(CalcState) handler,
  ) => _controller.stream.listen(handler);

  static void refresh() => _controller.add(_calcState);

  /// All completed calculations, newest first.
  static List<HistoryEntry> get historyLog => List.unmodifiable(_history);

  static bool get canUndo => _undoStack.isNotEmpty;

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

  static _Snapshot get _snapshot => _Snapshot(_valA, _valB, _operator, _result);

  static void _pushUndo([_Snapshot? snapshot]) {
    _undoStack.add(snapshot ?? _snapshot);
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  /// Records [before] only when input actually changed, so Undo never spends
  /// a step on a rejected key press (extra digits, duplicate decimal, etc.).
  static void _pushUndoIfChanged(_Snapshot before) {
    if (!before.matches(_snapshot)) _pushUndo(before);
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

  /// Restore completed calculations without changing current input or undo.
  static void restoreHistory() {
    final entries = HistoryStorage.instance.load();
    _history
      ..clear()
      ..addAll(
        entries.map(
          (entry) => HistoryEntry(
            id: entry.id,
            equation: entry.equation,
            result: entry.result,
          ),
        ),
      );
    _historyIdSeq = 0;
    for (final entry in _history) {
      if (entry.id >= _historyIdSeq) _historyIdSeq = entry.id + 1;
    }
    if (_historyIdSeq > HistoryStorage.maxId) _historyIdSeq = 0;
  }

  static void _saveHistory() {
    unawaited(
      HistoryStorage.instance.save(
        _history.map(
          (entry) => StoredCalculation(
            id: entry.id,
            equation: entry.equation,
            result: entry.result,
          ),
        ),
      ),
    );
  }

  static int _nextHistoryId() {
    while (_history.any((entry) => entry.id == _historyIdSeq)) {
      _historyIdSeq = (_historyIdSeq + 1) % (HistoryStorage.maxId + 1);
    }
    final id = _historyIdSeq;
    _historyIdSeq = (_historyIdSeq + 1) % (HistoryStorage.maxId + 1);
    return id;
  }

  static void clearHistory() {
    _history.clear();
    _saveHistory();
  }

  static HistoryDeletion? removeHistoryEntry(int id) {
    final index = _history.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final entry = _history.removeAt(index);
    _saveHistory();
    return HistoryDeletion._(entry, index);
  }

  /// Puts a deleted entry back in its original position.
  static bool restoreHistoryEntry(HistoryDeletion deletion) {
    if (_history.any((e) => e.id == deletion.entry.id)) return false;
    final index = deletion.index < _history.length
        ? deletion.index
        : _history.length;
    _history.insert(index, deletion.entry);
    if (_history.length > HistoryStorage.maxEntries) _history.removeLast();
    _saveHistory();
    return true;
  }

  /// Parses clipboard text as one finite number. Accepts surrounding
  /// whitespace, a leading + or Unicode minus, correctly grouped thousands
  /// ("1,234.5") and scientific notation. Returns null for anything else.
  static String? parsePastedNumber(String text) {
    var value = text.trim().replaceAll('\u2212', '-');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.contains(',')) {
      if (!RegExp(r'^-?[0-9]{1,3}(,[0-9]{3})+(\.[0-9]*)?$').hasMatch(value)) {
        return null;
      }
      value = value.replaceAll(',', '');
    }
    if (!HistoryStorage.isValidNumber(value)) return null;
    return _formatResult(double.parse(value));
  }

  /// Enters a pasted number as the current operand. Returns false (and leaves
  /// the calculator unchanged) when [text] is not a single finite number.
  static bool paste(String text) {
    final value = parsePastedNumber(text);
    if (value == null) return false;
    final before = _snapshot;
    if (_result != null) _clear();
    if (_operator == null) {
      _valA = value;
    } else {
      _valB = value;
    }
    _pushUndoIfChanged(before);
    refresh();
    return true;
  }

  /// Load a history result back into the calculator as the current value.
  static void setFromHistory(String result) {
    if (!HistoryStorage.isValidNumber(result)) return;
    final before = _snapshot;
    _clear();
    _valA = result;
    _pushUndoIfChanged(before);
    refresh();
  }

  // ── Key processing ────────────────────────────────────────────────────────

  static void process(dynamic event) {
    final before = _snapshot;
    final CalculatorKey key = (event as KeyEvent).key;
    switch (key.symbol.type) {
      case KeyType.function:
        _handleFunction(key);
        break;
      case KeyType.operator:
        _handleOperator(key);
        break;
      case KeyType.integer:
        _handleInteger(key);
        break;
    }
    _pushUndoIfChanged(before);
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
    // "5." is complete input; tidy it so equations read "5 + 3 =".
    _valA = _trimTrailingDecimal(_valA);
    if (_valB != null) _valB = _trimTrailingDecimal(_valB!);

    if (key.symbol == Keys.equals) {
      // Pressing "=" again on a shown result must not log a duplicate entry.
      if (_result != null) return;
      _calculate();
      refresh();
      return;
    }
    if (_valB != null) _calculate();
    if (_result != null) _condense();

    _operator = key.symbol;
    refresh();
  }

  static String _trimTrailingDecimal(String value) {
    if (!value.endsWith('.')) return value;
    final trimmed = value.substring(0, value.length - 1);
    return (trimmed.isEmpty || trimmed == '-' || trimmed == '-0')
        ? '0'
        : trimmed;
  }

  static void _handleInteger(CalculatorKey key) {
    final String val = key.symbol.value;
    // Typing after "=" starts a new number, as on standard calculators.
    // Operators, % and ± still continue from the result.
    if (_result != null) _clear();

    if (_operator == null) {
      if (val == '.') {
        if (!_valA.contains('.')) _valA = '$_valA.';
      } else {
        if (_countDigits(_valA) >= 9) return;
        _valA = (_valA == '0') ? val : '$_valA$val';
      }
    } else {
      if (_valB == null) {
        _valB = val == '.' ? '0.' : val;
      } else {
        if (val == '.') {
          if (!_valB!.contains('.')) _valB = '${_valB!}.';
        } else {
          if (_countDigits(_valB!) >= 9) return;
          _valB = (_valB == '0') ? val : '${_valB!}$val';
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
      _valB = _backspaceValue(_valB!);
    } else if (_operator != null) {
      _operator = null;
    } else if (_valA != '0') {
      _valA = _backspaceValue(_valA) ?? '0';
    }
  }

  static String? _backspaceValue(String value) {
    var remaining = value.substring(0, value.length - 1);
    // Never leave an unparseable sign or partial scientific exponent in an
    // operand. Percent and arithmetic must always receive a valid number.
    while (remaining.isNotEmpty && double.tryParse(remaining) == null) {
      remaining = remaining.substring(0, remaining.length - 1);
    }
    return remaining.isEmpty ? null : remaining;
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
    final value = double.tryParse(_valB ?? _valA);
    if (value == null || !value.isFinite) {
      _result = 'Error';
      return;
    }
    if (_valB != null) {
      _valB = _formatResult(value / 100);
    } else if (_valA != '0') {
      _valA = _formatResult(value / 100);
    }
  }

  static void _calculate() {
    if (_operator == null || _valB == null) return;

    final a = double.tryParse(_valA);
    final b = double.tryParse(_valB!);

    if (a == null || b == null || !a.isFinite || !b.isFinite) {
      _result = 'Error';
      refresh();
      return;
    }

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

    if (!result.isFinite) {
      _result = 'Error';
      refresh();
      return;
    }

    _result = _formatResult(result);

    _history.insert(
      0,
      HistoryEntry(
        id: _nextHistoryId(),
        equation: '$_valA ${_operator!.value} $_valB =',
        result: _result!,
      ),
    );
    if (_history.length > HistoryStorage.maxEntries) _history.removeLast();
    _saveHistory();

    refresh();
  }

  static String _formatResult(double value) {
    // Round away binary floating-point noise (0.1 + 0.2 = 0.3, not
    // 0.30000000000000004) while keeping 15 significant digits.
    final rounded = double.parse(value.toStringAsPrecision(15));
    if (rounded == 0) return '0';
    final str = rounded.toString();
    final exponentIndex = str.indexOf('e');
    var mantissa = exponentIndex < 0 ? str : str.substring(0, exponentIndex);
    final exponent = exponentIndex < 0 ? '' : str.substring(exponentIndex);
    if (mantissa.contains('.')) {
      mantissa = mantissa
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '');
    }
    return mantissa.isEmpty ? '0' : '$mantissa$exponent';
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
