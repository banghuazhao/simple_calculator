import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests run as Android, where the app now asks the native store bridge
/// for Premium. Without a host, report the bridge as missing so the app falls
/// back to the basic calculator immediately instead of waiting on a lookup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('simple_calculator/premium'),
          (_) async => throw MissingPluginException(),
        );
  });
  await testMain();
}
