import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/util/input_settings.dart';

abstract class InputFeedback {
  static Future<void> lightImpact() => _run(HapticFeedback.lightImpact);

  static Future<void> mediumImpact() => _run(HapticFeedback.mediumImpact);

  static Future<void> _run(Future<void> Function() feedback) async {
    if (!InputSettings.instance.hapticsEnabled) return;
    try {
      await feedback();
    } catch (error) {
      debugPrint('Input feedback unavailable: $error');
    }
  }
}
