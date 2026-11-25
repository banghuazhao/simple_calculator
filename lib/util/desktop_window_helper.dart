import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class DesktopWindowHelper extends ChangeNotifier {
  DesktopWindowHelper._();

  static final DesktopWindowHelper instance = DesktopWindowHelper._();
  static const channelName = 'com.appsbay.simple_calculator/window';
  static const _channel = MethodChannel(channelName);
  static const alwaysOnTopKey = 'macos_always_on_top_v1';

  bool _alwaysOnTop = false;
  bool get alwaysOnTop => _alwaysOnTop;

  Future<void> loadAndApply() async {
    try {
      final saved = StorageManager.sharedPreferences?.get(alwaysOnTopKey);
      _alwaysOnTop = saved is bool ? saved : false;
    } catch (_) {
      _alwaysOnTop = false;
    }
    notifyListeners();
    if (!kIsWeb && Platform.isMacOS) {
      await _applyNative(_alwaysOnTop);
    }
  }

  Future<void> setAlwaysOnTop(bool enabled) async {
    if (_alwaysOnTop == enabled) return;
    _alwaysOnTop = enabled;
    notifyListeners();
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs != null) {
        unawaited(prefs.setBool(alwaysOnTopKey, enabled));
      }
    } catch (_) {}
    if (!kIsWeb && Platform.isMacOS) {
      await _applyNative(enabled);
    }
  }

  Future<void> toggleAlwaysOnTop() => setAlwaysOnTop(!_alwaysOnTop);

  Future<void> _applyNative(bool enabled) async {
    try {
      await _channel.invokeMethod<bool>('setAlwaysOnTop', enabled);
    } on MissingPluginException {
      // Running in widget tests or unsupported platforms.
    } catch (error) {
      debugPrint('Always-on-top unavailable: $error');
    }
  }
}
