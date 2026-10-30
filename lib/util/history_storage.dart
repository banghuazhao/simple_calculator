import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/util/storage_manager.dart';

/// A validated completed calculation. History is optional app data, never input
/// that should be trusted directly when it comes back from storage.
class StoredCalculation {
  const StoredCalculation({
    required this.id,
    required this.equation,
    required this.result,
  });

  final int id;
  final String equation;
  final String result;

  Map<String, Object> toJson() => {
        'id': id,
        'equation': equation,
        'result': result,
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
  static const maxId = 0x1fffffffffffff;
  static const _maxPayloadLength = 64 * 1024;
  static const _maxNumberLength = 64;
  static const _numberPattern =
      r'-?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?';
  static final _number = RegExp('^$_numberPattern\$');
  static final _equation = RegExp(
    '^($_numberPattern) ([+×÷-]) ($_numberPattern) =\$',
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

  static bool _isValidEquation(String value) {
    if (value.length > 140) return false;
    final match = _equation.firstMatch(value);
    return match != null &&
        isValidNumber(match.group(1)!) &&
        isValidNumber(match.group(3)!);
  }

  static StoredCalculation? _decodeEntry(Object? value, Set<int> seen) {
    if (value is! Map) return null;
    final id = value['id'];
    final equation = value['equation'];
    final result = value['result'];
    if (id is! int ||
        id < 0 ||
        id > maxId ||
        seen.contains(id) ||
        equation is! String ||
        !_isValidEquation(equation) ||
        result is! String ||
        !isValidNumber(result)) {
      return null;
    }
    seen.add(id);
    return StoredCalculation(id: id, equation: equation, result: result);
  }

  /// Reads only the already-cached preferences. No platform call or wait is
  /// added to startup, and malformed data falls back to an empty history.
  List<StoredCalculation> load() {
    try {
      final raw = _preferences()?.get(preferencesKey);
      if (raw is! String || raw.length > _maxPayloadLength) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['entries'] is! List) {
        return const [];
      }
      final result = <StoredCalculation>[];
      final seen = <int>{};
      for (final candidate in decoded['entries'] as List) {
        final entry = _decodeEntry(candidate, seen);
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
        final entry = _decodeEntry(candidate.toJson(), seen);
        if (entry != null) validated.add(entry.toJson());
        if (validated.length == maxEntries) break;
      }
      _pending = _PendingHistoryWrite(
        preferences,
        jsonEncode({'version': 1, 'entries': validated}),
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
