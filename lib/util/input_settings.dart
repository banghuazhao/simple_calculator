import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class InputSettings extends ChangeNotifier {
  InputSettings._();

  static final InputSettings instance = InputSettings._();
  static const hapticsKey = 'input_haptics_enabled';
  static const shakeToUndoKey = 'input_shake_to_undo_enabled';
  static const soundEffectsKey = 'input_sound_effects_enabled';
  static const thousandsSeparatorKey = 'input_thousands_separator_enabled';
  static const commaDecimalKey = 'input_comma_decimal_enabled';
  static const memoryBarKey = 'input_memory_bar_enabled';
  static const repeatEqualsKey = 'input_repeat_equals_enabled';

  bool _hapticsEnabled = true;
  bool _shakeToUndoEnabled = true;
  bool _soundEffectsEnabled = false;
  bool _thousandsSeparatorEnabled = true;
  bool _commaDecimalEnabled = false;
  bool _memoryBarEnabled = false;
  bool _repeatEqualsEnabled = false;

  Future<void> _pendingWrites = Future<void>.value();
  final Map<String, int> _writeRevisions = {};
  int _loadGeneration = 0;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get shakeToUndoEnabled => _shakeToUndoEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get thousandsSeparatorEnabled => _thousandsSeparatorEnabled;
  bool get commaDecimalEnabled => _commaDecimalEnabled;
  bool get memoryBarEnabled => _memoryBarEnabled;
  bool get repeatEqualsEnabled => _repeatEqualsEnabled;

  String get decimalSeparator => _commaDecimalEnabled ? ',' : '.';
  String get groupingSeparator => _commaDecimalEnabled ? '.' : ',';

  /// Formats a numeric string according to the user's grouping and decimal
  /// separator preferences while keeping scientific notation readable.
  String formatDisplayNumber(String s) {
    if (s == 'Error') return s;
    if (s.contains('e') || s.contains('E')) {
      return _commaDecimalEnabled ? s.replaceAll('.', ',') : s;
    }

    final isNeg = s.startsWith('-');
    final abs = isNeg ? s.substring(1) : s;
    final dotIndex = abs.indexOf('.');
    final intStr = dotIndex >= 0 ? abs.substring(0, dotIndex) : abs;
    final rawDecStr = dotIndex >= 0 ? abs.substring(dotIndex) : '';
    final decStr = _commaDecimalEnabled
        ? rawDecStr.replaceFirst('.', ',')
        : rawDecStr;

    if (!_thousandsSeparatorEnabled || intStr.length <= 3) {
      return (isNeg ? '-' : '') + intStr + decStr;
    }

    final sep = groupingSeparator;
    final buf = StringBuffer();
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(sep);
      buf.write(intStr[i]);
    }
    return (isNeg ? '-' : '') + buf.toString() + decStr;
  }

  /// Reads only the already-loaded preferences, so settings add no startup wait.
  void load() {
    _loadGeneration++;
    _hapticsEnabled = _read(hapticsKey, defaultValue: true);
    _shakeToUndoEnabled = _read(shakeToUndoKey, defaultValue: true);
    _soundEffectsEnabled = _read(soundEffectsKey, defaultValue: false);
    _thousandsSeparatorEnabled = _read(
      thousandsSeparatorKey,
      defaultValue: true,
    );
    _commaDecimalEnabled = _read(commaDecimalKey, defaultValue: false);
    _memoryBarEnabled = _read(memoryBarKey, defaultValue: false);
    _repeatEqualsEnabled = _read(repeatEqualsKey, defaultValue: false);
    notifyListeners();
  }

  bool _read(String key, {required bool defaultValue}) {
    try {
      final value = StorageManager.sharedPreferences?.get(key);
      return value is bool ? value : defaultValue;
    } catch (error) {
      debugPrint('Input preference unavailable; using default: $error');
      return defaultValue;
    }
  }

  bool _currentValueFor(String key) => switch (key) {
    hapticsKey => _hapticsEnabled,
    shakeToUndoKey => _shakeToUndoEnabled,
    soundEffectsKey => _soundEffectsEnabled,
    thousandsSeparatorKey => _thousandsSeparatorEnabled,
    commaDecimalKey => _commaDecimalEnabled,
    memoryBarKey => _memoryBarEnabled,
    repeatEqualsKey => _repeatEqualsEnabled,
    _ => false,
  };

  void setHapticsEnabled(bool enabled) {
    if (_hapticsEnabled == enabled) return;
    _hapticsEnabled = enabled;
    notifyListeners();
    _save(hapticsKey, enabled);
  }

  void setShakeToUndoEnabled(bool enabled) {
    if (_shakeToUndoEnabled == enabled) return;
    _shakeToUndoEnabled = enabled;
    notifyListeners();
    _save(shakeToUndoKey, enabled);
  }

  void setSoundEffectsEnabled(bool enabled) {
    if (_soundEffectsEnabled == enabled) return;
    _soundEffectsEnabled = enabled;
    notifyListeners();
    _save(soundEffectsKey, enabled);
  }

  void setThousandsSeparatorEnabled(bool enabled) {
    if (_thousandsSeparatorEnabled == enabled) return;
    _thousandsSeparatorEnabled = enabled;
    notifyListeners();
    _save(thousandsSeparatorKey, enabled);
  }

  void setCommaDecimalEnabled(bool enabled) {
    if (_commaDecimalEnabled == enabled) return;
    _commaDecimalEnabled = enabled;
    notifyListeners();
    _save(commaDecimalKey, enabled);
  }

  void setMemoryBarEnabled(bool enabled) {
    if (_memoryBarEnabled == enabled) return;
    _memoryBarEnabled = enabled;
    notifyListeners();
    _save(memoryBarKey, enabled);
  }

  void setRepeatEqualsEnabled(bool enabled) {
    if (_repeatEqualsEnabled == enabled) return;
    _repeatEqualsEnabled = enabled;
    notifyListeners();
    _save(repeatEqualsKey, enabled);
  }

  void _save(String key, bool value) {
    final preferences = StorageManager.sharedPreferences;
    if (preferences == null) return;
    final revision = (_writeRevisions[key] ?? 0) + 1;
    _writeRevisions[key] = revision;
    final generation = _loadGeneration;
    // Queue rapid switches in the order they were made. A missing or stalled
    // platform service must never hold up the UI or subsequent settings.
    _pendingWrites = _pendingWrites.then((_) async {
      try {
        var timedOut = false;
        final write = preferences.setBool(key, value);
        // A native write may finish after its timeout. If it overwrote a newer
        // choice, reapply the current choice once that delayed write completes.
        unawaited(
          write.then<void>((_) {
            final currentValue = _currentValueFor(key);
            if (timedOut &&
                generation == _loadGeneration &&
                revision != _writeRevisions[key] &&
                value != currentValue) {
              _save(key, currentValue);
            }
          }, onError: (Object _, StackTrace _) {}),
        );
        await write.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            timedOut = true;
            throw TimeoutException('Input preference write timed out');
          },
        );
      } catch (error) {
        debugPrint('Input preference could not be saved: $error');
      }
    });
  }

  @visibleForTesting
  Future<void> get pendingWrites => _pendingWrites;
}
