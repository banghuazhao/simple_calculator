import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/history_expression.dart';
import 'package:simple_calculator/util/storage_manager.dart';

/// A validated completed calculation. History is optional app data, never input
/// that should be trusted directly when it comes back from storage.
class StoredCalculation {
  const StoredCalculation({
    required this.id,
    required this.equation,
    required this.result,
    this.rawResult,
    this.rawExpression,
    this.isPinned = false,
    this.name,
  });

  final int id;
  final String equation;
  final String result;
  final String? rawResult;
  final String? rawExpression;
  final bool isPinned;
  final String? name;

  Map<String, Object> toJson() => {
    'id': id,
    'equation': equation,
    'result': result,
    'rawResult': ?rawResult,
    'rawExpression': ?rawExpression,
    if (isPinned) 'pinned': true,
    'name': ?name,
  };
}

class HistoryStorage {
  HistoryStorage({
    SharedPreferences? Function()? preferences,
    this.writeTimeout = const Duration(seconds: 2),
  }) : _preferences = preferences ?? (() => StorageManager.sharedPreferences);

  static final HistoryStorage instance = HistoryStorage();
  static const preferencesKey = 'calculator_history_v1';
  static const maxEntries = 100;
  static const maxPinnedEntries = 25;
  static const maxNameLength = 60;
  static const maxId = 0x1fffffffffffff;
  static const _currentVersion = 2;
  // Include escaped names in the bound for a full history of long expressions.
  static const _maxPayloadLength = 80 * 1024;
  static const _maxNumberLength = 64;
  static final _nameSeparators = RegExp(r'[\s\x00-\x1f\x7f]+');
  static const _numberPattern =
      r'-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?';
  static final _number = RegExp('^$_numberPattern\$');
  static final _binaryEquation = RegExp(
    '^($_numberPattern) [+×÷-] ($_numberPattern)(%?) =\$',
  );

  final SharedPreferences? Function() _preferences;
  final Duration writeTimeout;
  _PendingHistoryWrite? _pending;
  Completer<void>? _idle;
  bool _writing = false;

  static bool isValidNumber(String value) =>
      value.isNotEmpty &&
      value.length <= _maxNumberLength &&
      _number.hasMatch(value) &&
      (double.tryParse(value)?.isFinite ?? false);

  static String normalizeName(String name) =>
      name.replaceAll(_nameSeparators, ' ').trim();

  static bool _isBinaryEquation(String value, {required bool allowPercent}) {
    if (value.length > 140) return false;
    final match = _binaryEquation.firstMatch(value);
    return match != null &&
        (allowPercent || match.group(3)!.isEmpty) &&
        isValidNumber(match.group(1)!) &&
        isValidNumber(match.group(2)!);
  }

  static bool _isValidEquation(String value, {required bool legacy}) {
    if (_isBinaryEquation(value, allowPercent: !legacy)) return true;
    if (legacy ||
        value.length > HistoryExpression.maxLength + 2 ||
        !value.endsWith(' =')) {
      return false;
    }
    final expression = HistoryExpression.fromEquation(value);
    if (expression != HistoryExpression.normalize(expression)) return false;
    try {
      HistoryExpression.evaluate(expression);
      return true;
    } on FormatException {
      return false;
    }
  }

  static StoredCalculation? _decodeEntry(
    Object? value,
    Set<int> seen, {
    required bool legacy,
  }) {
    if (value is! Map) return null;
    final id = value['id'];
    final equation = value['equation'];
    final result = value['result'];
    final rawResult = legacy ? null : value['rawResult'];
    final rawExpression = legacy ? null : value['rawExpression'];
    final savedName = legacy ? null : value['name'];
    if (id is! int ||
        id < 0 ||
        id > maxId ||
        seen.contains(id) ||
        equation is! String ||
        !_isValidEquation(equation, legacy: legacy) ||
        result is! String ||
        !isValidNumber(result) ||
        (rawResult != null &&
            (rawResult is! String || !isValidNumber(rawResult))) ||
        (rawExpression != null &&
            (rawExpression is! String ||
                !_isBinaryEquation(equation, allowPercent: true) ||
                !_isBinaryEquation('$rawExpression =', allowPercent: true)))) {
      return null;
    }
    seen.add(id);
    final name = savedName is String ? normalizeName(savedName) : '';
    return StoredCalculation(
      id: id,
      equation: equation,
      result: result,
      rawResult: rawResult as String?,
      rawExpression: rawExpression as String?,
      isPinned: !legacy && value['pinned'] == true,
      name: name.isNotEmpty && name.length <= maxNameLength ? name : null,
    );
  }

  /// Reads only the already-cached preferences. No platform call or wait is
  /// added to startup, and malformed data falls back to an empty history.
  List<StoredCalculation> load() {
    try {
      final raw = _preferences()?.get(preferencesKey);
      if (raw is! String || raw.length > _maxPayloadLength) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['entries'] is! List) return const [];
      final version = decoded['version'];
      if (version is! int || (version != 1 && version != _currentVersion)) {
        return const [];
      }
      final result = <StoredCalculation>[];
      final seen = <int>{};
      for (final candidate in decoded['entries'] as List) {
        final entry = _decodeEntry(candidate, seen, legacy: version == 1);
        if (entry != null) result.add(entry);
        if (result.length == maxEntries) break;
      }
      return result;
    } catch (_) {
      debugPrint('Saved history unavailable; using an empty history.');
      return const [];
    }
  }

  /// Queues the latest complete snapshot. Later clear/delete snapshots replace
  /// pending ones, while the actual native writes stay strictly ordered.
  Future<void> save(Iterable<StoredCalculation> entries) {
    try {
      final preferences = _preferences();
      if (preferences == null) return Future<void>.value();
      final validated = <Map<String, Object>>[];
      final seen = <int>{};
      for (final candidate in entries) {
        final entry = _decodeEntry(candidate.toJson(), seen, legacy: false);
        if (entry != null) validated.add(entry.toJson());
        if (validated.length == maxEntries) break;
      }
      _pending = _PendingHistoryWrite(
        preferences,
        jsonEncode({'version': _currentVersion, 'entries': validated}),
      );
      _idle ??= Completer<void>();
      if (!_writing) unawaited(_drain());
      return flush();
    } catch (error) {
      debugPrint('History could not be saved: $error');
      return Future<void>.value();
    }
  }

  /// Waiting is optional and bounded. A timed-out native operation continues
  /// to hold the write queue until it settles, preventing late stale writes.
  Future<void> flush() async {
    final idle = _idle;
    if (idle == null) return;
    try {
      await idle.future.timeout(writeTimeout);
    } on TimeoutException {
      debugPrint('History save is taking longer than expected.');
    }
  }

  Future<void> _drain() async {
    _writing = true;
    while (_pending != null) {
      final next = _pending!;
      _pending = null;
      try {
        final saved = await next.preferences.setString(
          preferencesKey,
          next.payload,
        );
        if (!saved) debugPrint('History storage declined the save.');
      } catch (error) {
        debugPrint('History could not be saved: $error');
      }
    }
    _writing = false;
    final idle = _idle;
    _idle = null;
    idle?.complete();
  }
}

class _PendingHistoryWrite {
  const _PendingHistoryWrite(this.preferences, this.payload);

  final SharedPreferences preferences;
  final String payload;
}
