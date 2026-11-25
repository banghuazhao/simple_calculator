import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:simple_calculator/premium/expression_engine.dart';
import 'package:simple_calculator/premium/formula_storage.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/unit_converter_page.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class BackupManager {
  static const int currentVersion = 1;
  static const String appIdentifier = 'SwiftSum';
  static const int maxBackupLength = 256 * 1024;

  static String exportJson(ThemeModel theme) {
    final history = HistoryStorage.instance.load();
    final formulas = FormulaStorage.instance.load();
    final settings = InputSettings.instance;
    List<Map<String, String>>? pinnedPairs;
    try {
      final rawPinned = StorageManager.sharedPreferences?.getString(
        UnitConverterPage.pinnedPairsKey,
      );
      if (rawPinned != null) {
        final decoded = jsonDecode(rawPinned);
        if (decoded is List) {
          pinnedPairs = decoded
              .map(UnitPairPreset.fromJson)
              .whereType<UnitPairPreset>()
              .map((p) => p.toJson())
              .toList();
        }
      }
    } catch (_) {}

    final payload = <String, Object?>{
      'app': appIdentifier,
      'version': currentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'history': history.map((entry) => entry.toJson()).toList(),
      'formulas': formulas.map((formula) => formula.toJson()).toList(),
      'theme': {
        'themeColor': theme.themeColor,
        'highContrastEnabled': theme.highContrastEnabled,
        'followSystemTheme': theme.followSystemTheme,
        'lightThemeIndex': theme.lightThemeIndex,
        'darkThemeIndex': theme.darkThemeIndex,
        'useCustomTheme': theme.useCustomTheme,
        'customPalette': theme.customPalette.toJson(),
      },
      'inputSettings': {
        'hapticsEnabled': settings.hapticsEnabled,
        'shakeToUndoEnabled': settings.shakeToUndoEnabled,
        'soundEffectsEnabled': settings.soundEffectsEnabled,
        'thousandsSeparatorEnabled': settings.thousandsSeparatorEnabled,
        'commaDecimalEnabled': settings.commaDecimalEnabled,
        'memoryBarEnabled': settings.memoryBarEnabled,
        'repeatEqualsEnabled': settings.repeatEqualsEnabled,
      },
      'pinnedUnitPairs': ?pinnedPairs,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<bool> importJson(String raw, ThemeModel theme) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > maxBackupLength) return false;

    final Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return false;
    }
    if (decoded is! Map ||
        decoded['app'] != appIdentifier ||
        decoded['version'] != currentVersion) {
      return false;
    }

    // Validate all sections before applying any mutation.
    List<StoredCalculation>? parsedHistory;
    if (decoded.containsKey('history')) {
      final rawHistory = decoded['history'];
      if (rawHistory is! List) return false;
      final list = <StoredCalculation>[];
      final seen = <int>{};
      for (final item in rawHistory) {
        if (item is! Map) return false;
        final id = item['id'];
        final equation = item['equation'];
        final result = item['result'];
        if (id is! int ||
            id < 0 ||
            id > HistoryStorage.maxId ||
            seen.contains(id) ||
            equation is! String ||
            result is! String ||
            !HistoryStorage.isValidNumber(result)) {
          return false;
        }
        seen.add(id);
        final rawResult = item['rawResult'];
        final rawExpression = item['rawExpression'];
        final name = item['name'];
        final timestampMs = item['timestampMs'];
        list.add(
          StoredCalculation(
            id: id,
            equation: equation,
            result: result,
            rawResult: rawResult is String ? rawResult : null,
            rawExpression: rawExpression is String ? rawExpression : null,
            isPinned: item['pinned'] == true,
            name: name is String ? HistoryStorage.normalizeName(name) : null,
            timestampMs: timestampMs is int && timestampMs > 0
                ? timestampMs
                : null,
          ),
        );
        if (list.length == HistoryStorage.maxEntries) break;
      }
      parsedHistory = list;
    }

    List<SavedFormula>? parsedFormulas;
    if (decoded.containsKey('formulas')) {
      final rawFormulas = decoded['formulas'];
      if (rawFormulas is! List ||
          rawFormulas.length > FormulaStorage.maxFormulas) {
        return false;
      }
      final list = <SavedFormula>[];
      for (final entry in rawFormulas) {
        final formula = _parseFormula(entry);
        if (formula == null) return false;
        list.add(formula);
      }
      parsedFormulas = list;
    }

    Map<String, Object?>? themeData;
    if (decoded.containsKey('theme')) {
      final rawTheme = decoded['theme'];
      if (rawTheme is! Map) return false;
      themeData = rawTheme.map((k, v) => MapEntry(k.toString(), v));
    }

    Map<String, Object?>? inputData;
    if (decoded.containsKey('inputSettings')) {
      final rawInput = decoded['inputSettings'];
      if (rawInput is! Map) return false;
      inputData = rawInput.map((k, v) => MapEntry(k.toString(), v));
    }

    List<UnitPairPreset>? parsedPairs;
    if (decoded.containsKey('pinnedUnitPairs')) {
      final rawPairs = decoded['pinnedUnitPairs'];
      if (rawPairs is! List) return false;
      final list = <UnitPairPreset>[];
      for (final item in rawPairs) {
        final pair = UnitPairPreset.fromJson(item);
        if (pair == null) return false;
        if (!list.contains(pair)) list.add(pair);
      }
      parsedPairs = list;
    }

    try {
      if (parsedHistory != null) {
        await HistoryStorage.instance.save(parsedHistory);
        Processor.restoreHistory();
      }
      if (parsedFormulas != null) {
        await FormulaStorage.instance.save(parsedFormulas);
      }
      if (themeData != null) {
        _applyTheme(theme, themeData);
      }
      if (inputData != null) {
        _applyInputSettings(inputData);
      }
      if (parsedPairs != null) {
        final prefs = StorageManager.sharedPreferences;
        if (prefs != null) {
          await prefs.setString(
            UnitConverterPage.pinnedPairsKey,
            jsonEncode(parsedPairs.map((p) => p.toJson()).toList()),
          );
        }
      }
      return true;
    } catch (error) {
      debugPrint('Backup import failed: $error');
      return false;
    }
  }

  static SavedFormula? _parseFormula(Object? entry) {
    if (entry is! Map) return null;
    final name = entry['name'];
    final expression = entry['expression'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > FormulaStorage.maxNameLength ||
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
    if (variables.length > FormulaStorage.maxInputs) return null;
    final baseline = _parseValues(entry['baseline'], variables);
    final alternate = _parseValues(entry['alternate'], variables);
    if (baseline == null || alternate == null) return null;

    final metadata = <String, FormulaInputMetadata>{};
    final rawMeta = entry['inputMetadata'];
    if (rawMeta != null) {
      if (rawMeta is! Map) return null;
      for (final pair in rawMeta.entries) {
        final key = pair.key;
        final val = pair.value;
        if (key is! String || !variables.contains(key) || val is! Map) {
          return null;
        }
        final label = val['label'];
        final unit = val['unit'];
        metadata[key] = FormulaInputMetadata(
          label: label is String ? label.trim() : '',
          unit: unit is String ? unit.trim() : '',
        );
      }
    }
    final baselineName = entry['baselineName'];
    final alternateName = entry['alternateName'];
    return SavedFormula(
      name: name,
      expression: expression,
      baseline: baseline,
      alternate: alternate,
      inputMetadata: metadata,
      baselineName: baselineName is String ? baselineName.trim() : '',
      alternateName: alternateName is String ? alternateName.trim() : '',
    );
  }

  static Map<String, double>? _parseValues(Object? raw, Set<String> names) {
    if (raw is! Map) return null;
    final map = <String, double>{};
    for (final entry in raw.entries) {
      final k = entry.key;
      final v = entry.value;
      if (k is! String || !names.contains(k) || v is! num || !v.isFinite) {
        return null;
      }
      map[k] = v.toDouble();
    }
    return map;
  }

  static void _applyTheme(ThemeModel theme, Map<String, Object?> data) {
    final palette = CustomThemePalette.fromJson(data['customPalette']);
    final themeColor = data['themeColor'];
    if (themeColor is int &&
        themeColor >= 0 &&
        themeColor < ThemeModel.themeCount) {
      theme.switchTheme(themeColor);
    }
    final lightIndex = data['lightThemeIndex'];
    if (lightIndex is int &&
        lightIndex >= 0 &&
        lightIndex < ThemeModel.themeCount) {
      theme.setLightThemeIndex(lightIndex);
    }
    final darkIndex = data['darkThemeIndex'];
    if (darkIndex is int &&
        darkIndex >= 0 &&
        darkIndex < ThemeModel.themeCount) {
      theme.setDarkThemeIndex(darkIndex);
    }
    final followSystem = data['followSystemTheme'];
    if (followSystem is bool) {
      theme.setFollowSystemTheme(followSystem);
    }
    if (palette != null && data['useCustomTheme'] == true) {
      theme.setCustomPalette(palette);
    }
    final highContrast = data['highContrastEnabled'];
    if (highContrast is bool) {
      theme.setHighContrastEnabled(highContrast);
    }
  }

  static void _applyInputSettings(Map<String, Object?> data) {
    final settings = InputSettings.instance;
    if (data['hapticsEnabled'] case final bool v) {
      settings.setHapticsEnabled(v);
    }
    if (data['shakeToUndoEnabled'] case final bool v) {
      settings.setShakeToUndoEnabled(v);
    }
    if (data['soundEffectsEnabled'] case final bool v) {
      settings.setSoundEffectsEnabled(v);
    }
    if (data['thousandsSeparatorEnabled'] case final bool v) {
      settings.setThousandsSeparatorEnabled(v);
    }
    if (data['commaDecimalEnabled'] case final bool v) {
      settings.setCommaDecimalEnabled(v);
    }
    if (data['memoryBarEnabled'] case final bool v) {
      settings.setMemoryBarEnabled(v);
    }
    if (data['repeatEqualsEnabled'] case final bool v) {
      settings.setRepeatEqualsEnabled(v);
    }
  }
}
