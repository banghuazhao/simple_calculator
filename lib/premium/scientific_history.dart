import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class ScientificHistoryEntry {
  const ScientificHistoryEntry({
    required this.expression,
    required this.degrees,
    this.answer,
    required this.result,
  });

  factory ScientificHistoryEntry.fromJson(Map<String, Object?> json) {
    final expression = json['expression'];
    final degrees = json['degrees'];
    final answer = json['answer'];
    final result = json['result'];
    if (expression is! String ||
        degrees is! bool ||
        (answer != null && answer is! num) ||
        result is! num) {
      throw const FormatException('Invalid scientific history entry');
    }
    final entry = ScientificHistoryEntry(
      expression: expression,
      degrees: degrees,
      answer: (answer as num?)?.toDouble(),
      result: result.toDouble(),
    );
    if (!entry._isValid) {
      throw const FormatException('Invalid scientific history entry');
    }
    return entry;
  }

  final String expression;
  final bool degrees;

  /// The value of Ans when the expression was evaluated.
  final double? answer;
  final double result;

  bool get _isValid =>
      expression.length <= ExpressionEngine.maxLength &&
      expression.trim().isNotEmpty &&
      (answer?.isFinite ?? true) &&
      result.isFinite;

  Map<String, Object> toJson() => {
    'expression': expression,
    'degrees': degrees,
    'answer': ?answer,
    'result': result,
  };
}

class ScientificHistory {
  ScientificHistory({SharedPreferences? Function()? preferences})
    : _preferences = preferences ?? (() => StorageManager.sharedPreferences);

  static final instance = ScientificHistory();
  static const preferencesKey = 'calculator_scientific_history_v1';
  static const maxEntries = 100;
  // JSON can escape each character as six code units. Allow the worst-case
  // expansion plus the record fields, while bounding untrusted saved data.
  static const _maxPayloadLength =
      maxEntries * (ExpressionEngine.maxLength * 6 + 128) + 32;

  final SharedPreferences? Function() _preferences;
  late final List<ScientificHistoryEntry> _entries = _restore();
  (SharedPreferences, String)? _pendingWrite;
  Completer<void>? _writeIdle;

  List<ScientificHistoryEntry> get entries => List.unmodifiable(_entries);

  /// Updates the session immediately. The returned future settles when the
  /// native write queue empties.
  Future<void> add(ScientificHistoryEntry entry) {
    if (!entry._isValid) return Future<void>.value();
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) _entries.removeLast();

    final preferences = _preferences();
    if (preferences == null) return Future<void>.value();
    _pendingWrite = (
      preferences,
      jsonEncode({'version': 1, 'entries': _entries}),
    );
    final current = _writeIdle;
    if (current != null) return current.future;

    final idle = _writeIdle = Completer<void>();
    unawaited(_writePending(idle));
    return idle.future;
  }

  List<ScientificHistoryEntry> _restore() {
    final entries = <ScientificHistoryEntry>[];
    try {
      final payload = _preferences()?.get(preferencesKey);
      if (payload is! String || payload.length > _maxPayloadLength) {
        return entries;
      }
      final data = jsonDecode(payload);
      if (data case {'version': 1, 'entries': List<Object?> records}) {
        for (final record in records) {
          if (record is! Map<String, Object?>) continue;
          try {
            entries.add(ScientificHistoryEntry.fromJson(record));
          } on FormatException {
            continue;
          }
          if (entries.length == maxEntries) break;
        }
      }
    } catch (_) {
      debugPrint('Saved scientific history is unavailable.');
    }
    return entries;
  }

  Future<void> _writePending(Completer<void> idle) async {
    // Finish the active write before consuming the newest snapshot. Dropping an
    // obsolete pending snapshot keeps memory bounded if native storage stalls.
    while (_pendingWrite != null) {
      final (preferences, payload) = _pendingWrite!;
      _pendingWrite = null;
      try {
        final saved = await preferences.setString(preferencesKey, payload);
        if (!saved) debugPrint('Scientific history storage declined the save.');
      } catch (_) {
        debugPrint('Scientific history could not be saved.');
      }
    }
    _writeIdle = null;
    idle.complete();
  }
}
