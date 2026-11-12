import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class SavedFormula {
  SavedFormula({
    required this.name,
    required this.expression,
    required Map<String, double> baseline,
    required Map<String, double> alternate,
  }) : baseline = Map.unmodifiable(baseline),
       alternate = Map.unmodifiable(alternate);

  final String name;
  final String expression;
  final Map<String, double> baseline;
  final Map<String, double> alternate;

  Map<String, Object> toJson() => {
    'name': name,
    'expression': expression,
    'baseline': baseline,
    'alternate': alternate,
  };
}

class FormulaStorage {
  FormulaStorage({SharedPreferences? Function()? preferences})
    : _preferences = preferences ?? (() => StorageManager.sharedPreferences);

  static final instance = FormulaStorage();
  static const preferencesKey = 'calculator_formulas_v1';
  static const maxFormulas = 30;
  static const maxInputs = 12;
  static const maxNameLength = 80;
  static const maxValueLength = 48;
  static const _maxPayloadLength = 128 * 1024;

  final SharedPreferences? Function() _preferences;
  bool _writing = false;

  static double? parseValue(String text) {
    if (text.length > maxValueLength) return null;
    final value = double.tryParse(text.trim().replaceAll('−', '-'));
    return value != null && value.isFinite ? value : null;
  }

  static SavedFormula? _decodeFormula(Object? entry) {
    if (entry is! Map) return null;
    final name = entry['name'];
    final expression = entry['expression'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > maxNameLength ||
        expression is! String ||
        expression.isEmpty ||
        expression.length > ExpressionEngine.maxLength) {
      return null;
    }

    final Set<String> variables;
    try {
      variables = ExpressionEngine.variablesIn(expression);
    } on FormatException {
      return null;
    }
    if (variables.length > maxInputs) return null;

    final baseline = _decodeValues(entry['baseline'], variables);
    final alternate = _decodeValues(entry['alternate'], variables);
    if (baseline == null || alternate == null) return null;
    return SavedFormula(
      name: name,
      expression: expression,
      baseline: baseline,
      alternate: alternate,
    );
  }

  static Map<String, double>? _decodeValues(Object? input, Set<String> names) {
    if (input is! Map || input.length > names.length) return null;
    final values = <String, double>{};
    for (final entry in input.entries) {
      final name = entry.key;
      final value = entry.value;
      if (name is! String || !names.contains(name) || value is! num) {
        return null;
      }
      final parsed = value.toDouble();
      if (!parsed.isFinite) return null;
      values[name] = parsed;
    }
    return values;
  }

  List<SavedFormula> load() {
    try {
      final raw = _preferences()?.get(preferencesKey);
      if (raw is! String || raw.length > _maxPayloadLength) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != 1) return const [];
      final entries = decoded['formulas'];
      if (entries is! List) return const [];

      final formulas = <SavedFormula>[];
      for (final entry in entries) {
        final formula = _decodeFormula(entry);
        if (formula != null) formulas.add(formula);
        if (formulas.length == maxFormulas) break;
      }
      return formulas;
    } catch (error) {
      debugPrint('Saved formulas unavailable: $error');
      return const [];
    }
  }

  Future<bool> save(List<SavedFormula> formulas) {
    if (_writing || formulas.length > maxFormulas) return Future.value(false);
    _writing = true;
    // A delayed native write still owns the lock until it settles, so a retry
    // cannot finish first and be overwritten by the older snapshot.
    return _write(
      formulas,
    ).timeout(const Duration(seconds: 3), onTimeout: () => false);
  }

  Future<bool> _write(List<SavedFormula> formulas) async {
    try {
      final preferences = _preferences();
      if (preferences == null) return false;
      final entries = formulas.map((formula) => formula.toJson()).toList();
      if (entries.any((entry) => _decodeFormula(entry) == null)) return false;
      final payload = jsonEncode({'version': 1, 'formulas': entries});
      if (payload.length > _maxPayloadLength) return false;
      return await preferences.setString(preferencesKey, payload);
    } catch (error) {
      debugPrint('Could not save formulas: $error');
      return false;
    } finally {
      _writing = false;
    }
  }
}
