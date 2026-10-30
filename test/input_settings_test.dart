import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class _ControlledPreferences extends Fake implements SharedPreferences {
  final values = <String, Object>{};
  final writes = <(String, bool)>[];
  Completer<bool>? firstWrite;
  bool failWrites = false;
  bool failReads = false;

  @override
  Object? get(String key) {
    if (failReads) throw StateError('read unavailable');
    return values[key];
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    writes.add((key, value));
    if (writes.length == 1 && firstWrite != null) await firstWrite!.future;
    if (failWrites) throw StateError('write unavailable');
    values[key] = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final settings = InputSettings.instance;

  Future<void> load(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await StorageManager.init();
    settings.load();
  }

  setUp(() async {
    await settings.pendingWrites;
    await load({});
  });

  test(
    'defaults preserve haptics and shake when preferences are unavailable',
    () async {
      await StorageManager.init(
        loadPreferences: () async {
          throw PlatformException(code: 'preferences_unavailable');
        },
      );
      settings.load();
      expect(settings.hapticsEnabled, isTrue);
      expect(settings.shakeToUndoEnabled, isTrue);
      settings.setHapticsEnabled(false);
      settings.setShakeToUndoEnabled(false);
      await settings.pendingWrites;
      expect(settings.hapticsEnabled, isFalse);
      expect(settings.shakeToUndoEnabled, isFalse);
    },
  );

  test(
    'valid preferences are restored and independent of each other',
    () async {
      await load({
        InputSettings.hapticsKey: false,
        InputSettings.shakeToUndoKey: true,
      });
      expect(settings.hapticsEnabled, isFalse);
      expect(settings.shakeToUndoEnabled, isTrue);
    },
  );

  test(
    'invalid preference types fall back to the original enabled behavior',
    () async {
      await load({
        InputSettings.hapticsKey: 'false',
        InputSettings.shakeToUndoKey: 0,
      });
      expect(settings.hapticsEnabled, isTrue);
      expect(settings.shakeToUndoEnabled, isTrue);
    },
  );

  test('switches update the session immediately and survive reload', () async {
    settings.setHapticsEnabled(false);
    settings.setShakeToUndoEnabled(false);
    expect(settings.hapticsEnabled, isFalse);
    expect(settings.shakeToUndoEnabled, isFalse);
    await settings.pendingWrites;
    settings.load();
    expect(settings.hapticsEnabled, isFalse);
    expect(settings.shakeToUndoEnabled, isFalse);
    settings.setHapticsEnabled(true);
    settings.setShakeToUndoEnabled(true);
    await settings.pendingWrites;
    settings.load();
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.shakeToUndoEnabled, isTrue);
  });

  test(
    'failed writes preserve session choices and allow subsequent changes',
    () async {
      final preferences = _ControlledPreferences()..failWrites = true;
      await StorageManager.init(loadPreferences: () async => preferences);
      settings.load();
      settings.setHapticsEnabled(false);
      settings.setShakeToUndoEnabled(false);
      await settings.pendingWrites;
      expect(settings.hapticsEnabled, isFalse);
      expect(settings.shakeToUndoEnabled, isFalse);
      preferences.failWrites = false;
      settings.setHapticsEnabled(true);
      await settings.pendingWrites;
      expect(preferences.values[InputSettings.hapticsKey], isTrue);
    },
  );

  test('preference read failures use defaults without throwing', () async {
    final preferences = _ControlledPreferences()..failReads = true;
    await StorageManager.init(loadPreferences: () async => preferences);
    expect(settings.load, returnsNormally);
    expect(settings.hapticsEnabled, isTrue);
    expect(settings.shakeToUndoEnabled, isTrue);
  });

  test('rapid switch writes are serialized in user order', () async {
    final pending = Completer<bool>();
    final preferences = _ControlledPreferences()..firstWrite = pending;
    await StorageManager.init(loadPreferences: () async => preferences);
    settings.load();
    settings.setHapticsEnabled(false);
    settings.setHapticsEnabled(true);
    await Future<void>.delayed(Duration.zero);
    expect(preferences.writes, [(InputSettings.hapticsKey, false)]);
    expect(settings.hapticsEnabled, isTrue);
    pending.complete(true);
    await settings.pendingWrites;
    expect(preferences.writes, [
      (InputSettings.hapticsKey, false),
      (InputSettings.hapticsKey, true),
    ]);
    expect(preferences.values[InputSettings.hapticsKey], isTrue);
  });

  test(
    'stalled writes do not block newer choices or restore stale values',
    () async {
      final pending = Completer<bool>();
      final preferences = _ControlledPreferences()..firstWrite = pending;
      await StorageManager.init(loadPreferences: () async => preferences);
      settings.load();
      settings.setHapticsEnabled(false);
      settings.setHapticsEnabled(true);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 3100));
        expect(settings.hapticsEnabled, isTrue);
        expect(preferences.values[InputSettings.hapticsKey], isTrue);
      } finally {
        pending.complete(true);
        await Future<void>.delayed(Duration.zero);
        await settings.pendingWrites;
      }
      expect(preferences.values[InputSettings.hapticsKey], isTrue);
      expect(preferences.writes, [
        (InputSettings.hapticsKey, false),
        (InputSettings.hapticsKey, true),
        (InputSettings.hapticsKey, true),
      ]);
    },
  );

  test(
    'a late write matching the current choice needs no corrective write',
    () async {
      final pending = Completer<bool>();
      final preferences = _ControlledPreferences()..firstWrite = pending;
      await StorageManager.init(loadPreferences: () async => preferences);
      settings.load();
      settings.setHapticsEnabled(false);
      settings.setHapticsEnabled(true);
      settings.setHapticsEnabled(false);
      try {
        await Future<void>.delayed(const Duration(milliseconds: 3100));
        expect(settings.hapticsEnabled, isFalse);
        expect(preferences.values[InputSettings.hapticsKey], isFalse);
      } finally {
        pending.complete(true);
        await Future<void>.delayed(Duration.zero);
        await settings.pendingWrites;
      }
      expect(preferences.values[InputSettings.hapticsKey], isFalse);
      expect(preferences.writes, [
        (InputSettings.hapticsKey, false),
        (InputSettings.hapticsKey, true),
        (InputSettings.hapticsKey, false),
      ]);
    },
  );

  test('disabled haptics skip all platform feedback calls', () async {
    var calls = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls++;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    settings.setHapticsEnabled(false);
    await InputFeedback.lightImpact();
    await InputFeedback.mediumImpact();
    await settings.pendingWrites;
    expect(calls, 0);
  });

  test('enabled feedback survives an unavailable platform service', () async {
    final types = <Object?>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        types.add(call.arguments);
        throw PlatformException(code: 'haptics_unavailable');
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await InputFeedback.lightImpact();
    await InputFeedback.mediumImpact();
    expect(types, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets('large-text input switches remain usable and localized', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    tester.platformDispatcher.textScaleFactorTestValue = 3.2;
    await tester.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeModel(),
        child: MaterialApp(
          locale: const Locale('zh', 'HK'),
          supportedLocales: S.delegate.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: SingleChildScrollView(child: InputSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(S.current.inputSettings), findsOneWidget);
    final haptics = find.byKey(const ValueKey('haptics-setting'));
    final shake = find.byKey(const ValueKey('shake-setting'));
    await tester.ensureVisible(haptics);
    await tester.tap(haptics);
    await tester.pumpAndSettle();
    expect(settings.hapticsEnabled, isFalse);
    await tester.ensureVisible(shake);
    await tester.tap(shake);
    await tester.pumpAndSettle();
    expect(settings.shakeToUndoEnabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
