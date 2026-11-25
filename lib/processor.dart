import 'dart:async';

import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/history_expression.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/calculator_draft_storage.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';

enum OperandPosition { left, right }

enum OperandCorrection { applied, invalid, stale }

/// The value seen when opening the number editor. The revision keeps a dialog
/// opened for an older calculation from changing the current one.
class OperandEdit {
  const OperandEdit._({
    required this.position,
    required this.display,
    required this.input,
    required int revision,
  }) : _revision = revision;

  final OperandPosition position;
  final String display;
  final String input;
  final int _revision;
}

/// Structured output emitted on every state change.
class CalcState {
  final String current; // main large display
  final String history; // small equation line above (empty when not applicable)
  final bool isResult; // true when showing a freshly computed result
  final bool canUndo;
  final bool canRedo;
  final String? preview; // live preview before pressing =
  final String? memory; // formatted saved memory value, if non-null
  final OperandEdit? leftOperand;
  final OperandEdit? rightOperand;
  final String? binaryOperator;
  final bool rightOperandIsPercent;
  final bool clearShowsAllClear;
  final bool canClearEntry;

  const CalcState({
    required this.current,
    required this.history,
    this.isResult = false,
    this.canUndo = false,
    this.canRedo = false,
    this.preview,
    this.memory,
    this.leftOperand,
    this.rightOperand,
    this.binaryOperator,
    this.rightOperandIsPercent = false,
    this.clearShowsAllClear = false,
    this.canClearEntry = false,
  });
}

/// A single completed calculation kept in the history log.
class HistoryEntry {
  final int id;
  final String equation; // e.g. "3 + 4 ="
  final String result;
  final String? rawResult;
  final String? rawExpression;
  final bool isPinned;
  final String? name;
  final int? timestampMs;
  const HistoryEntry({
    required this.id,
    required this.equation,
    required this.result,
    this.rawResult,
    this.rawExpression,
    this.isPinned = false,
    this.name,
    this.timestampMs,
  });

  String get preciseResult => rawResult ?? result;
  String get expression =>
      rawExpression ?? HistoryExpression.fromEquation(equation);

  HistoryEntry _withDetails({required bool isPinned, required String? name}) =>
      HistoryEntry(
        id: id,
        equation: equation,
        result: result,
        rawResult: rawResult,
        rawExpression: rawExpression,
        isPinned: isPinned,
        name: name,
        timestampMs: timestampMs,
      );
}

/// A removed history entry and where it was, so deletion can be undone.
class HistoryDeletion {
  final HistoryEntry entry;
  final int index;
  const HistoryDeletion._(this.entry, this.index);
}

// Text remains editable and readable. Keep a separate value when formatting
// the text for the display would lose precision for the next operation.
typedef _Number = CalculatorNumber;
typedef _Calculation = CalculatorResult;
typedef _Snapshot = CalculatorDraft;

abstract class Processor {
  static const _Number _zero = (text: '0', preciseValue: null);
  static const _error = calculatorErrorResult;
  static const _memoryKey = 'calculator_memory_v1';
  static const int maxInputDigits = 15;

  static KeySymbol? _operator;
  static _Number _valA = _zero;
  static _Number? _valB;
  static bool _percentB = false;
  static _Calculation? _result;
  static int _inputRevision = 0;
  static double? _memory;

  static final List<HistoryEntry> _history = [];
  static final List<_Snapshot> _undoStack = [];
  static final List<_Snapshot> _redoStack = [];
  static int _historyIdSeq = 0;

  static final StreamController<CalcState> _controller =
      StreamController<CalcState>.broadcast();

  static StreamSubscription<CalcState> listen(
    void Function(CalcState) handler,
  ) => _controller.stream.listen(handler);

  static void refresh() => _controller.add(_calcState);

  /// The latest state is also available synchronously for the first frame.
  static CalcState get state => _calcState;

  /// Current displayed finite numeric value, useful for bridging to tools.
  static double? get currentNumericValue {
    final result = _result;
    if (result == _error) return null;
    final active = result?.number ?? (_valB ?? _valA);
    final value = _valueOf(active);
    return value != null && value.isFinite ? value : null;
  }

  /// Pinned calculations first, newest to oldest within each group.
  static List<HistoryEntry> get historyLog => List.unmodifiable([
    ..._history.where((entry) => entry.isPinned),
    ..._history.where((entry) => !entry.isPinned),
  ]);

  static bool get canUndo => _undoStack.isNotEmpty;
  static bool get canRedo => _redoStack.isNotEmpty;
  static bool get hasMemory => _memory != null;
  static double? get memoryValue => _memory;

  static String? _computePreview() {
    if (_result != null) return null;
    final operator = _operator;
    final right = _valB;
    if (operator == null || right == null) return null;
    final a = _valueOf(_valA);
    final rightValue = _valueOf(right);
    if (a == null || rightValue == null || !a.isFinite || !rightValue.isFinite) {
      return null;
    }
    final b = _percentB
        ? HistoryExpression.percentOperand(a, operator.value, rightValue)
        : rightValue;
    final value = switch (operator) {
      Keys.divide => a / b,
      Keys.multiply => a * b,
      Keys.subtract => a - b,
      _ => a + b,
    };
    if (!value.isFinite) return null;
    return formatResult(value);
  }

  static CalcState get _calcState {
    final result = _result;
    final operator = _operator;
    final right = _valB;
    final expression = operator == null
        ? ''
        : '${_valA.text} ${operator.value}${_percentB ? ' ${right!.text}%' : ''}';
    // A full expression recalled from history has no independently editable
    // left or right operand. Basic results keep their original operands.
    final editable = result == null || operator != null || result == _error;
    return CalcState(
      current: result?.number.text ?? (right ?? _valA).text,
      history: result?.equation ?? expression,
      isResult: result != null,
      canUndo: canUndo,
      canRedo: canRedo,
      preview: _computePreview(),
      memory: _memory == null ? null : formatResult(_memory!),
      leftOperand: editable ? _editFor(OperandPosition.left, _valA) : null,
      rightOperand: right == null
          ? null
          : _editFor(OperandPosition.right, right),
      binaryOperator: operator?.value,
      rightOperandIsPercent: _percentB,
      clearShowsAllClear:
          result == null &&
          operator != null &&
          (right == null || right == _zero),
      canClearEntry:
          result == null &&
          operator != null &&
          right != null &&
          right != _zero,
    );
  }

  static OperandEdit _editFor(OperandPosition position, _Number number) =>
      OperandEdit._(
        position: position,
        display: number.text,
        input: number.preciseValue?.toString() ?? number.text,
        revision: _inputRevision,
      );

  static void dispose() => _controller.close();

  // ── Memory ───────────────────────────────────────────────────────────────

  static void restoreMemory() {
    try {
      final raw = StorageManager.sharedPreferences?.get(_memoryKey);
      if (raw is double && raw.isFinite) {
        _memory = raw;
      } else if (raw is int) {
        _memory = raw.toDouble();
      } else {
        _memory = null;
      }
    } catch (_) {
      _memory = null;
    }
    refresh();
  }

  static void _saveMemory() {
    final prefs = StorageManager.sharedPreferences;
    if (prefs == null) return;
    final value = _memory;
    if (value == null) {
      unawaited(prefs.remove(_memoryKey));
    } else {
      unawaited(prefs.setDouble(_memoryKey, value));
    }
  }

  static void memoryClear() {
    if (_memory == null) return;
    _memory = null;
    _saveMemory();
    refresh();
  }

  static void memoryAdd() {
    final value = currentNumericValue;
    if (value == null) return;
    final updated = (_memory ?? 0) + value;
    if (!updated.isFinite) return;
    _memory = updated;
    _saveMemory();
    refresh();
  }

  static void memorySubtract() {
    final value = currentNumericValue;
    if (value == null) return;
    final updated = (_memory ?? 0) - value;
    if (!updated.isFinite) return;
    _memory = updated;
    _saveMemory();
    refresh();
  }

  static void memoryRecall() {
    final value = _memory;
    if (value == null || !value.isFinite) return;
    final before = _snapshot;
    final number = _formattedNumber(value);
    if (_result != null) {
      _clear();
      _valA = number;
    } else if (_operator == null) {
      _valA = number;
    } else {
      _valB = number;
      _percentB = false;
    }
    _finishAction(before);
  }

  // ── Undo & Redo ──────────────────────────────────────────────────────────

  static _Snapshot get _snapshot => (
    valA: _valA,
    valB: _valB,
    op: _operator,
    percentB: _percentB,
    result: _result,
  );

  /// Each accepted action records undo and publishes one finalized state.
  static void _finishAction(_Snapshot before) {
    if (before == _snapshot) return;
    _undoStack.add(before);
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
    _publishMutation();
  }

  static void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshot);
    if (_redoStack.length > 30) _redoStack.removeAt(0);
    _applySnapshot(_undoStack.removeLast());
    _publishMutation();
  }

  static void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshot);
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _applySnapshot(_redoStack.removeLast());
    _publishMutation();
  }

  /// Restore the last on-screen draft without replaying its keys or writing
  /// another history entry. Undo starts a fresh session.
  static void restoreDraft() {
    final draft = CalculatorDraftStorage.instance.load();
    _undoStack.clear();
    _redoStack.clear();
    if (draft == null) {
      _clear();
    } else {
      _applySnapshot(draft);
    }
    _inputRevision++;
    refresh();
  }

  static void _applySnapshot(_Snapshot snapshot) {
    _valA = snapshot.valA;
    _valB = snapshot.valB;
    _operator = snapshot.op;
    _percentB = snapshot.percentB;
    _result = snapshot.result;
  }

  static void _publishMutation() {
    _inputRevision++;
    unawaited(CalculatorDraftStorage.instance.save(_snapshot));
    refresh();
  }

  // ── History ───────────────────────────────────────────────────────────────

  /// Restore completed calculations without changing current input or undo.
  static void restoreHistory() {
    final entries = HistoryStorage.instance.load();
    var remainingPins = HistoryStorage.maxPinnedEntries;
    _history
      ..clear()
      ..addAll(
        entries.map((entry) {
          final isPinned = entry.isPinned && remainingPins > 0;
          if (isPinned) remainingPins--;
          return HistoryEntry(
            id: entry.id,
            equation: entry.equation,
            result: entry.result,
            rawResult: entry.rawResult,
            rawExpression: entry.rawExpression,
            isPinned: isPinned,
            name: entry.name,
            timestampMs: entry.timestampMs,
          );
        }),
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
            rawResult: entry.rawResult,
            rawExpression: entry.rawExpression,
            isPinned: entry.isPinned,
            name: entry.name,
            timestampMs: entry.timestampMs,
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

  static bool get canPinHistoryEntry =>
      _history.where((entry) => entry.isPinned).length <
      HistoryStorage.maxPinnedEntries;

  static bool setHistoryPinned(int id, bool isPinned) {
    final index = _history.indexWhere((entry) => entry.id == id);
    if (index < 0) return false;
    final entry = _history[index];
    if (entry.isPinned == isPinned) return true;
    if (isPinned && !canPinHistoryEntry) return false;
    _history[index] = entry._withDetails(isPinned: isPinned, name: entry.name);
    _saveHistory();
    return true;
  }

  static bool renameHistoryEntry(int id, String input) {
    final name = HistoryStorage.normalizeName(input);
    if (name.length > HistoryStorage.maxNameLength) return false;
    final index = _history.indexWhere((entry) => entry.id == id);
    if (index < 0) return false;
    final entry = _history[index];
    final updatedName = name.isEmpty ? null : name;
    if (entry.name == updatedName) return true;
    _history[index] = entry._withDetails(
      isPinned: entry.isPinned,
      name: updatedName,
    );
    _saveHistory();
    return true;
  }

  static void _trimHistory({int? keepId}) {
    if (_history.length <= HistoryStorage.maxEntries) return;
    final oldestUnpinned = _history.lastIndexWhere(
      (entry) => !entry.isPinned && entry.id != keepId,
    );
    _history.removeAt(oldestUnpinned);
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
    final original = deletion.entry;
    final entry = original.isPinned && !canPinHistoryEntry
        ? original._withDetails(isPinned: false, name: original.name)
        : original;
    _history.insert(index, entry);
    _trimHistory(keepId: entry.id);
    _saveHistory();
    return true;
  }

  /// Parses clipboard text as one finite number. Accepts surrounding
  /// whitespace, a leading + or Unicode minus, correctly grouped thousands
  /// ("1,234.5") and scientific notation. Returns null for anything else.
  static double? parseNumericInput(String text) {
    var value = text.trim().replaceAll('\u2212', '-');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.contains(',')) {
      if (InputSettings.instance.commaDecimalEnabled &&
          RegExp(
            r'^-?(?:[0-9]{1,3}(\.[0-9]{3})+|[0-9]+),[0-9]*(?:[eE][+-]?[0-9]+)?$',
          ).hasMatch(value)) {
        value = value.replaceAll('.', '').replaceFirst(',', '.');
      } else {
        if (!RegExp(r'^-?[0-9]{1,3}(,[0-9]{3})+(\.[0-9]*)?$').hasMatch(value)) {
          return null;
        }
        value = value.replaceAll(',', '');
      }
    }
    if (!HistoryStorage.isValidNumber(value)) return null;
    return double.parse(value);
  }

  static String? parsePastedNumber(String text) {
    final value = parseNumericInput(text);
    return value == null ? null : formatResult(value);
  }

  /// Replaces one operand without evaluating the expression. For a completed
  /// binary calculation this returns to the editable expression, while the
  /// original result remains in history.
  static OperandCorrection correctOperand(OperandEdit edit, String text) {
    if (edit._revision != _inputRevision) return OperandCorrection.stale;
    final previous = switch (edit.position) {
      OperandPosition.left => _valA,
      OperandPosition.right => _valB,
    };
    if (previous == null) return OperandCorrection.stale;

    final value = parseNumericInput(text);
    if (value == null) return OperandCorrection.invalid;
    if (value == _valueOf(previous)) return OperandCorrection.applied;

    final before = _snapshot;
    final number = _formattedNumber(value);
    switch (edit.position) {
      case OperandPosition.left:
        _valA = number;
      case OperandPosition.right:
        _valB = number;
    }
    _result = null;
    _finishAction(before);
    return OperandCorrection.applied;
  }

  /// Enters a pasted number as the current operand. Returns false (and leaves
  /// the calculator unchanged) when [text] is not a single finite number.
  static bool paste(String text) {
    final value = parseNumericInput(text);
    if (value == null) return false;
    final before = _snapshot;
    if (_result != null) _clear();
    final number = _formattedNumber(value);
    if (_operator == null) {
      _valA = number;
    } else {
      _valB = number;
      _percentB = false;
    }
    _finishAction(before);
    return true;
  }

  /// Load a history result back into the calculator as the current value, or
  /// as the right operand when [asOperandIfPending] is true and an operator is
  /// waiting for its second operand.
  static void setFromHistory(
    String result, {
    String? preciseResult,
    bool asOperandIfPending = false,
  }) {
    if (!HistoryStorage.isValidNumber(result)) return;
    final preciseValue = preciseResult == null
        ? null
        : double.tryParse(preciseResult);
    final number = _number(result, preciseValue: preciseValue);
    if (asOperandIfPending &&
        _result == null &&
        _operator != null &&
        _valB == null) {
      final before = _snapshot;
      _valB = number;
      _percentB = false;
      _finishAction(before);
      return;
    }
    _useNumber(number);
  }

  /// Send a result from another tool to the calculator without rounding it.
  static void useResult(double value) {
    if (value.isFinite) _useNumber(_formattedNumber(value));
  }

  static void _useNumber(_Number number) {
    final before = _snapshot;
    _clear();
    _valA = number;
    _finishAction(before);
  }

  /// Evaluate an edited expression and save it as a separate history entry.
  static bool rerunHistory(String expression) {
    final normalized = HistoryExpression.normalize(expression);
    final double value;
    try {
      value = HistoryExpression.evaluate(normalized);
    } on FormatException {
      return false;
    }
    final before = _snapshot;
    _clear();
    _completeCalculation(normalized, value);
    _finishAction(before);
    return true;
  }

  // ── Key processing ────────────────────────────────────────────────────────

  static void process(KeyEvent event) {
    final before = _snapshot;
    final symbol = event.key.symbol;
    switch (symbol.type) {
      case KeyType.function:
        _handleFunction(symbol);
        break;
      case KeyType.operator:
        _handleOperator(symbol);
        break;
      case KeyType.integer:
        _handleInteger(symbol.value);
        break;
    }
    _finishAction(before);
  }

  static void clearAll() {
    final before = _snapshot;
    _clear();
    _finishAction(before);
  }

  static void clearEntry() {
    final before = _snapshot;
    if (_result == null &&
        _operator != null &&
        _valB != null &&
        _valB != _zero) {
      _valB = _zero;
      _percentB = false;
    } else {
      _clear();
    }
    _finishAction(before);
  }

  static void _handleFunction(KeySymbol symbol) {
    if (_result != null) _condense();

    switch (symbol) {
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
  }

  static void _handleOperator(KeySymbol symbol) {
    // "5." is complete input; tidy it so equations read "5 + 3 =".
    _valA = _trimTrailingDecimal(_valA);
    if (_valB != null) _valB = _trimTrailingDecimal(_valB!);

    if (symbol == Keys.equals) {
      if (_result != null) {
        if (InputSettings.instance.repeatEqualsEnabled &&
            _result != _error &&
            _operator != null &&
            _valB != null) {
          _valA = _result!.number;
          _result = null;
          _calculate();
        }
        return;
      }
      _calculate();
      return;
    }
    if (_result == null && _valB != null) {
      _calculate();
      if (_result == _error) return;
    }
    if (_result != null) _condense();

    _operator = symbol;
  }

  static _Number _trimTrailingDecimal(_Number number) {
    final text = number.text;
    if (!text.endsWith('.')) return number;
    final trimmed = text.substring(0, text.length - 1);
    return trimmed == '-0'
        ? _zero
        : _number(trimmed, preciseValue: number.preciseValue);
  }

  static void _handleInteger(String value) {
    // Typing after "=" starts a new number, as on standard calculators.
    // Operators, % and ± still continue from the result.
    if (_result != null) _clear();

    if (_operator == null) {
      _valA = _appendInput(_valA, value);
    } else {
      _valB = _appendInput(_percentB ? _zero : _valB ?? _zero, value);
      _percentB = false;
    }
  }

  static _Number _appendInput(_Number number, String value) {
    final text = number.text;
    if (value == '.') {
      // Appending a decimal after a recalled exponent would corrupt the number.
      if (text.contains(RegExp(r'[.eE]'))) return number;
      return _number('$text.');
    }
    if (_countDigits(text) >= maxInputDigits) return number;
    return _number(text == '0' ? value : '$text$value');
  }

  static int _countDigits(String s) =>
      s.replaceAll(RegExp(r'[^0-9]'), '').length;

  static void _back() {
    if (_percentB) {
      _percentB = false;
    } else if (_valB != null) {
      _valB = _backspaceValue(_valB!);
    } else if (_operator != null) {
      _operator = null;
    } else if (_valA.text != '0') {
      _valA = _backspaceValue(_valA) ?? _zero;
    }
  }

  static _Number? _backspaceValue(_Number number) {
    final value = number.text;
    var remaining = value.substring(0, value.length - 1);
    // Never leave an unparseable sign or partial scientific exponent in an
    // operand. Percent and arithmetic must always receive a valid number.
    while (remaining.isNotEmpty && double.tryParse(remaining) == null) {
      remaining = remaining.substring(0, remaining.length - 1);
    }
    return remaining.isEmpty ? null : _number(remaining);
  }

  static void _clear() {
    _valA = _zero;
    _valB = null;
    _percentB = false;
    _operator = null;
    _result = null;
  }

  static void _sign() {
    if (_valB != null) {
      _valB = _negate(_valB!);
    } else if (_valA.text != '0') {
      _valA = _negate(_valA);
    }
  }

  static _Number _negate(_Number number) {
    final text = number.text;
    final preciseValue = number.preciseValue;
    return _number(
      text.startsWith('-') ? text.substring(1) : '-$text',
      preciseValue: preciseValue == null ? null : -preciseValue,
    );
  }

  static void _percent() {
    final value = _valueOf(_valB ?? _valA);
    if (value == null || !value.isFinite) {
      _result = _error;
      return;
    }
    if (_valB != null) {
      _valB = _trimTrailingDecimal(_valB!);
      _percentB = true;
    } else if (_valA.text != '0') {
      _valA = _formattedNumber(value / 100);
    }
  }

  static void _calculate() {
    final operator = _operator;
    final right = _valB;
    if (operator == null || right == null) return;
    final a = _valueOf(_valA);
    final rightValue = _valueOf(right);
    if (a == null ||
        rightValue == null ||
        !a.isFinite ||
        !rightValue.isFinite) {
      _result = _error;
      return;
    }

    final b = _percentB
        ? HistoryExpression.percentOperand(a, operator.value, rightValue)
        : rightValue;
    final result = switch (operator) {
      Keys.divide => a / b,
      Keys.multiply => a * b,
      Keys.subtract => a - b,
      _ => a + b,
    };

    if (!result.isFinite) {
      _result = _error;
      return;
    }

    final unit = _percentB ? '%' : '';
    final expression = '${_valA.text} ${operator.value} ${right.text}$unit';
    final rawExpression =
        '${_valA.preciseValue ?? _valA.text} ${operator.value} '
        '${right.preciseValue ?? right.text}$unit';
    _completeCalculation(expression, result, rawExpression: rawExpression);
  }

  static void _completeCalculation(
    String expression,
    double value, {
    String? rawExpression,
  }) {
    final equation = '$expression =';
    final number = _formattedNumber(value);
    _result = (equation: equation, number: number);
    _history.insert(
      0,
      HistoryEntry(
        id: _nextHistoryId(),
        equation: equation,
        result: number.text,
        rawResult: number.preciseValue?.toString(),
        rawExpression: rawExpression == expression ? null : rawExpression,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _trimHistory();
    _saveHistory();
  }

  static _Number _number(String text, {double? preciseValue}) {
    final needsPrecision =
        preciseValue != null &&
        preciseValue.isFinite &&
        preciseValue != double.tryParse(text);
    return (text: text, preciseValue: needsPrecision ? preciseValue : null);
  }

  static _Number _formattedNumber(double value) =>
      _number(formatResult(value), preciseValue: value);

  static double? _valueOf(_Number number) =>
      number.preciseValue ?? double.tryParse(number.text);

  static String formatResult(double value) {
    // Round away binary floating-point noise (0.1 + 0.2 = 0.3, not
    // 0.30000000000000004) while keeping 15 significant digits.
    final rounded = double.parse(value.toStringAsPrecision(15));
    if (rounded == 0) return '0';
    final str = (rounded.isFinite ? rounded : value).toString();
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
    if (_result == _error) {
      _clear();
      return;
    }
    final number = _result!.number;
    _clear();
    _valA = number;
  }
}
