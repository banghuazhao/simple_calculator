import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/util/shake_listener.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/main.dart' as app;

class _WriteFailingPreferences extends Fake implements SharedPreferences {
  @override
  Object? get(String key) => 0;

  @override
  Future<bool> setInt(String key, int value) async {
    throw PlatformException(code: 'write_failed');
  }
}

class _DisposeFailingAd extends Fake implements Ad {
  @override
  Future<void> dispose() async {
    throw PlatformException(code: 'ad_dispose_failed');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unavailable preferences still allow the default theme to initialize',
      () async {
    await StorageManager.init(loadPreferences: () async {
      throw PlatformException(code: 'storage_unavailable');
    });

    expect(StorageManager.sharedPreferences, isNull);
    final theme = ThemeModel();
    expect(theme.themeColor, 0);
    expect(() => theme.switchTheme(1), returnsNormally);
  });

  test(
      'stalled preferences have a bounded wait and cannot replace fallback later',
      () async {
    final pending = Completer<SharedPreferences>();
    await StorageManager.init(
      timeout: const Duration(milliseconds: 1),
      loadPreferences: () => pending.future,
    );
    expect(ThemeModel().themeColor, 0);

    SharedPreferences.setMockInitialValues({ThemeModel.kThemeColorIndex: 2});
    pending.complete(await SharedPreferences.getInstance());
    await Future<void>.delayed(Duration.zero);
    expect(StorageManager.sharedPreferences, isNull);
  });

  for (final saved in <Object>['invalid', -1, 99]) {
    test('invalid saved theme $saved does not prevent opening', () async {
      SharedPreferences.setMockInitialValues(
          {ThemeModel.kThemeColorIndex: saved});
      await StorageManager.init();
      expect(ThemeModel().themeColor, 0);
    });
  }

  test('a valid saved theme is preserved', () async {
    SharedPreferences.setMockInitialValues({ThemeModel.kThemeColorIndex: 17});
    await StorageManager.init();
    expect(ThemeModel().themeColor, 17);
  });

  test(
      'a failed settings write preserves the session without an uncaught error',
      () async {
    await StorageManager.init(
        loadPreferences: () async => _WriteFailingPreferences());
    final theme = ThemeModel();
    theme.switchTheme(2);
    await Future<void>.delayed(Duration.zero);
    expect(theme.themeColor, 2);
  });

  test('an unavailable accelerometer is handled without an uncaught error',
      () async {
    var shakes = 0;
    final events = StreamController<AccelerometerEvent>();
    final listener = ShakeListener(onShake: () => shakes++)
      ..listen(events.stream);
    events.addError(PlatformException(code: 'NO_SENSOR'));
    await Future<void>.delayed(Duration.zero);
    expect(shakes, 0);
    expect(events.hasListener, isFalse);
    await listener.dispose();
    await events.close();
  });

  test('sensor cancellation failure does not escape cleanup', () async {
    final events = StreamController<AccelerometerEvent>(onCancel: () async {
      throw PlatformException(code: 'cancel_failed');
    });
    final listener = ShakeListener(onShake: () {})..listen(events.stream);
    await listener.dispose();
    await events.close();
  });

  test('ad disposal failure does not escape cleanup', () async {
    await AdsManager.disposeAd(_DisposeFailingAd());
  });

  testWidgets('orientation failure cannot prevent the first calculator frame',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var orientationRequested = false;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientationRequested = true;
        throw PlatformException(code: 'orientation_unavailable');
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await app.main();
    await tester.pumpAndSettle();
    expect(find.byType(app.CalculatorApp), findsOneWidget);
    expect(orientationRequested, isTrue);
    expect(tester.takeException(), isNull);
  });
}
