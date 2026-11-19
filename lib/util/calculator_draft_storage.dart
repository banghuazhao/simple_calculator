import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/history_expression.dart';
import 'package:simple_calculator/key_symbol.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/storage_manager.dart';

typedef CalculatorNumber = ({String text, double? preciseValue});
typedef CalculatorResult = ({String equation, CalculatorNumber number});
typedef CalculatorDraft = ({
  CalculatorNumber valA,
  CalculatorNumber? valB,
  KeySymbol? op,
  bool percentB,
  CalculatorResult? result,
});

const CalculatorResult calculatorErrorResult = (
  equation: '',
  number: (text: 'Error', preciseValue: null),
);

class CalculatorDraftStorage {
  CalculatorDraftStorage({SharedPreferences? Function()? preferences})
    : _preferences = preferences ?? (() => StorageManager.sharedPreferences);

  static final instance = CalculatorDraftStorage();
  static const preferencesKey = 'calculator_draft_v1';
  static const _maxPayloadLength = 4096;

  final SharedPreferences? Function() _preferences;
  (SharedPreferences, String)? _pendingWrite;
  Completer<void>? _writeIdle;

  /// Uses the cached preferences loaded during app startup.
  CalculatorDraft? load() {
    try {
      final stored = _preferences()?.get(preferencesKey);
      if (stored is! String || stored.length > _maxPayloadLength) return null;
      final decoded = jsonDecode(stored);
      if (decoded is! Map ||
          decoded['version'] is! int ||
          decoded['version'] != 1) {
        return null;
      }

      final left = _numberFromJson(decoded['left']);
      final right = _numberFromJson(decoded['right']);
      final operator = switch (decoded['operator']) {
        '+' => Keys.add,
        '-' => Keys.subtract,
        '×' => Keys.multiply,
        '÷' => Keys.divide,
        _ => null,
      };
      final percent = decoded['percent'];
      if (left == null ||
          (decoded['right'] != null && right == null) ||
          (decoded['operator'] != null && operator == null) ||
          (right != null && operator == null) ||
          percent is! bool ||
          (percent && right == null)) {
        return null;
      }

      final savedResult = decoded['result'];
      final CalculatorResult? result;
      if (savedResult == null) {
        result = null;
      } else if (savedResult == 'error') {
        result = calculatorErrorResult;
      } else if (savedResult case {
        'equation': final String equation,
        'number': final number,
      }) {
        final value = _numberFromJson(number);
        if (value == null ||
            !_validEquation(equation, left, operator, right, percent)) {
          return null;
        }
        result = (equation: equation, number: value);
      } else {
        return null;
      }

      return (
        valA: left,
        valB: right,
        op: operator,
        percentB: percent,
        result: result,
      );
    } catch (_) {
      debugPrint('Saved calculator draft is unavailable.');
      return null;
    }
  }

  Future<void> save(CalculatorDraft draft) {
    try {
      final preferences = _preferences();
      if (preferences == null) return Future<void>.value();
      final result = draft.result;
      _pendingWrite = (
        preferences,
        jsonEncode({
          'version': 1,
          'left': _numberToJson(draft.valA),
          if (draft.valB case final right?) 'right': _numberToJson(right),
          'operator': ?draft.op?.value,
          'percent': draft.percentB,
          if (result != null)
            'result': result == calculatorErrorResult
                ? 'error'
                : {
                    'equation': result.equation,
                    'number': _numberToJson(result.number),
                  },
        }),
      );
      if (_writeIdle case final idle?) return idle.future;
      final idle = _writeIdle = Completer<void>();
      unawaited(_drain(idle));
      return idle.future;
    } catch (_) {
      debugPrint('Calculator draft could not be saved.');
      return Future<void>.value();
    }
  }

  /// Wait for queued snapshots when an explicit persistence check is needed.
  Future<void> flush() => _writeIdle?.future ?? Future<void>.value();

  Future<void> _drain(Completer<void> idle) async {
    // Keep one latest pending value and wait for the active native write to
    // settle before starting it, so no stale snapshot can win a race.
    while (_pendingWrite != null) {
      final (preferences, payload) = _pendingWrite!;
      _pendingWrite = null;
      try {
        final saved = await preferences.setString(preferencesKey, payload);
        if (!saved) debugPrint('Calculator draft storage declined the save.');
      } catch (_) {
        debugPrint('Calculator draft could not be saved.');
      }
    }
    _writeIdle = null;
    idle.complete();
  }

  static CalculatorNumber? _numberFromJson(Object? value) {
    if (value is! Map || value['text'] is! String) return null;
    final text = value['text'] as String;
    if (!HistoryStorage.isValidNumber(text)) return null;
    final raw = value['precise'];
    if (raw == null) return (text: text, preciseValue: null);
    if (raw is! num || !raw.isFinite) return null;
    return (text: text, preciseValue: raw.toDouble());
  }

  static Map<String, Object> _numberToJson(CalculatorNumber number) => {
    'text': number.text,
    'precise': ?number.preciseValue,
  };

  static bool _validEquation(
    String equation,
    CalculatorNumber left,
    KeySymbol? operator,
    CalculatorNumber? right,
    bool percent,
  ) {
    if (operator != null) {
      return right != null &&
          equation ==
              '${left.text} ${operator.value} ${right.text}${percent ? '%' : ''} =';
    }
    if (!equation.endsWith(' =')) return false;
    final expression = HistoryExpression.fromEquation(equation);
    if (expression != HistoryExpression.normalize(expression)) return false;
    try {
      HistoryExpression.evaluate(expression);
      return true;
    } on FormatException {
      return false;
    }
  }
}
