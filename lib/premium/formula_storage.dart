import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class FormulaInputMetadata {
  const FormulaInputMetadata({this.label = '', this.unit = ''});

  final String label;
  final String unit;

  Map<String, String> toJson() => {
    if (label.isNotEmpty) 'label': label,
    if (unit.isNotEmpty) 'unit': unit,
  };
}

class SavedFormula {
  SavedFormula({
    required this.name,
    required this.expression,
    required Map<String, double> baseline,
    required Map<String, double> alternate,
    Map<String, FormulaInputMetadata> inputMetadata = const {},
    this.baselineName = '',
    this.alternateName = '',
  }) : inputMetadata = Map.unmodifiable(inputMetadata),
       baseline = Map.unmodifiable(baseline),
       alternate = Map.unmodifiable(alternate);

  final String name;
  final String expression;
  final Map<String, double> baseline;
  final Map<String, double> alternate;
  final Map<String, FormulaInputMetadata> inputMetadata;
  final String baselineName;
  final String alternateName;

  Map<String, Object> toJson() => {
    'name': name,
    'expression': expression,
    'baseline': baseline,
    'alternate': alternate,
    if (inputMetadata.isNotEmpty)
      'inputMetadata': inputMetadata.map(
        (name, metadata) => MapEntry(name, metadata.toJson()),
      ),
    if (baselineName.isNotEmpty) 'baselineName': baselineName,
    if (alternateName.isNotEmpty) 'alternateName': alternateName,
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
  static const maxInputLabelLength = 60;
  static const maxUnitLength = 24;
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
    final inputMetadata = _decodeInputMetadata(
      entry['inputMetadata'],
      variables,
    );
    final baselineName = _optionalText(entry['baselineName'], maxNameLength);
    final alternateName = _optionalText(entry['alternateName'], maxNameLength);
    if (baseline == null ||
        alternate == null ||
        inputMetadata == null ||
        baselineName == null ||
        alternateName == null) {
      return null;
    }
    return SavedFormula(
      name: name,
      expression: expression,
      baseline: baseline,
      alternate: alternate,
      inputMetadata: inputMetadata,
      baselineName: baselineName,
      alternateName: alternateName,
    );
  }

  static Map<String, FormulaInputMetadata>? _decodeInputMetadata(
    Object? input,
    Set<String> names,
  ) {
    if (input == null) return const {};
    if (input is! Map || input.length > names.length) return null;
    final metadata = <String, FormulaInputMetadata>{};
    for (final entry in input.entries) {
      final name = entry.key;
      final details = entry.value;
      if (name is! String || !names.contains(name) || details is! Map) {
        return null;
      }
      final label = _optionalText(details['label'], maxInputLabelLength);
      final unit = _optionalText(details['unit'], maxUnitLength);
      if (label == null || unit == null) return null;
      if (label.isNotEmpty || unit.isNotEmpty) {
        metadata[name] = FormulaInputMetadata(label: label, unit: unit);
      }
    }
    return metadata;
  }

  static String? _optionalText(Object? value, int maxLength) {
    if (value == null) return '';
    return value is String && value.length <= maxLength ? value.trim() : null;
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
