import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Optional shake-to-undo input. Missing or restricted sensors disable this
/// shortcut without interrupting normal calculator input.
class ShakeListener {
  ShakeListener({required this.onShake});

  final VoidCallback onShake;
  StreamSubscription<AccelerometerEvent>? _subscription;
  double _lastX = 0, _lastY = 9.8, _lastZ = 0;
  DateTime? _lastShake;

  void listen(Stream<AccelerometerEvent> events) {
    _subscription = events.listen((event) {
      final dx = event.x - _lastX;
      final dy = event.y - _lastY;
      final dz = event.z - _lastZ;
      _lastX = event.x;
      _lastY = event.y;
      _lastZ = event.z;
      if (dx * dx + dy * dy + dz * dz > 350) {
        final now = DateTime.now();
        if (_lastShake == null ||
            now.difference(_lastShake!) > const Duration(milliseconds: 900)) {
          _lastShake = now;
          onShake();
        }
      }
    }, onError: (Object error, StackTrace stack) {
      debugPrint('Shake-to-undo unavailable: $error');
    }, cancelOnError: true);
  }

  Future<void> dispose() async {
    try {
      await _subscription?.cancel();
    } catch (error) {
      debugPrint('Shake-to-undo cleanup unavailable: $error');
    }
  }
}
