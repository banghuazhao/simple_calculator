import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/shake_listener.dart';
import 'package:simple_calculator/util/storage_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final settings = InputSettings.instance;
  late StreamController<AccelerometerEvent> events;
  ShakeListener? listener;

  Future<void> emit(double x) async {
    events.add(AccelerometerEvent(x, 0, 0, DateTime.now()));
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
    settings.load();
    events = StreamController<AccelerometerEvent>();
    listener = null;
  });

  tearDown(() async {
    await listener?.dispose();
    await events.close();
    await settings.pendingWrites;
  });

  test(
    'shake preference is live and disabled movement does not consume cooldown',
    () async {
      var shakes = 0;
      listener = ShakeListener(
        onShake: () => shakes++,
        isEnabled: () => settings.shakeToUndoEnabled,
      )..listen(events.stream);

      settings.setShakeToUndoEnabled(false);
      await emit(40);
      expect(shakes, 0);

      settings.setShakeToUndoEnabled(true);
      // The coordinates were still updated while disabled, so holding still
      // must not generate a delayed shake when the preference is re-enabled.
      await emit(40);
      expect(shakes, 0);
      // A real new movement is immediately eligible: disabled events did not
      // start the 900 ms cooldown.
      await emit(-40);
      expect(shakes, 1);
      await emit(40);
      expect(shakes, 1);
    },
  );

  test(
    'omitting the preference predicate preserves enabled shake detection',
    () async {
      var shakes = 0;
      listener = ShakeListener(onShake: () => shakes++)..listen(events.stream);
      await emit(40);
      expect(shakes, 1);
    },
  );

  test(
    'an unavailable sensor is handled even when shake input is disabled',
    () async {
      var shakes = 0;
      settings.setShakeToUndoEnabled(false);
      listener = ShakeListener(
        onShake: () => shakes++,
        isEnabled: () => settings.shakeToUndoEnabled,
      )..listen(events.stream);
      events.addError(PlatformException(code: 'NO_SENSOR'));
      await Future<void>.delayed(Duration.zero);
      expect(events.hasListener, isFalse);
      settings.setShakeToUndoEnabled(true);
      await emit(40);
      expect(shakes, 0);
    },
  );
}
