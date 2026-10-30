import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  /// app全局配置 eg:theme
  static SharedPreferences? _sharedPreferences;
  static SharedPreferences? get sharedPreferences => _sharedPreferences;

  /// 必备数据的初始化操作
  ///
  /// 由于是同步操作会导致阻塞,所以应尽量减少存储容量
  static Future<void> init({
    Duration timeout = const Duration(seconds: 3),
    Future<SharedPreferences> Function()? loadPreferences,
  }) async {
    _sharedPreferences = null;
    try {
      _sharedPreferences =
          await (loadPreferences ?? SharedPreferences.getInstance)()
              .timeout(timeout);
    } catch (error) {
      // Saved appearance is optional. A storage failure must not stop the
      // calculator from opening with its default theme.
      debugPrint('Saved settings unavailable; using defaults: $error');
    }
  }

  static Future<void> saveInt(String key, int value) async {
    try {
      await _sharedPreferences?.setInt(key, value);
    } catch (error) {
      debugPrint(
          'Could not save settings; keeping the current session: $error');
    }
  }
}
