import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class InputSettings extends ChangeNotifier {
  InputSettings._();

  static final InputSettings instance = InputSettings._();
  static const hapticsKey = 'input_haptics_enabled';
  static const shakeToUndoKey = 'input_shake_to_undo_enabled';

  bool _hapticsEnabled = true;
  bool _shakeToUndoEnabled = true;
  Future<void> _pendingWrites = Future<void>.value();
  final Map<String, int> _writeRevisions = {};
  int _loadGeneration = 0;

  bool get hapticsEnabled => _hapticsEnabled;
  bool get shakeToUndoEnabled => _shakeToUndoEnabled;

  /// Reads only the already-loaded preferences, so settings add no startup wait.
  void load() {
    _loadGeneration++;
    _hapticsEnabled = _read(hapticsKey);
    _shakeToUndoEnabled = _read(shakeToUndoKey);
    notifyListeners();
  }

  bool _read(String key) {
    try {
      final value = StorageManager.sharedPreferences?.get(key);
      return value is bool ? value : true;
    } catch (error) {
      debugPrint('Input preference unavailable; using default: $error');
      return true;
    }
  }

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
            final currentValue = key == hapticsKey
                ? _hapticsEnabled
                : _shakeToUndoEnabled;
            if (timedOut &&
                generation == _loadGeneration &&
                revision != _writeRevisions[key] &&
                value != currentValue) {
              _save(key, currentValue);
            }
          }, onError: (Object _, StackTrace __) {}),
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
