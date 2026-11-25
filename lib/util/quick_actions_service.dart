import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class QuickActionsService {
  QuickActionsService._();

  static final QuickActionsService instance = QuickActionsService._();
  static const channelName = 'com.appsbay.simple_calculator/quick_actions';
  static const _channel = MethodChannel(channelName);

  static const actionUnitConverter = 'unit_converter';
  static const actionEverydayTools = 'everyday_tools';
  static const actionHistory = 'history';
  static const actionScientific = 'scientific';

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool _initialized = false;

  StreamSubscription<String> listen(void Function(String action) onAction) {
    _ensureInitialized();
    return _controller.stream.listen(onAction);
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcut' && call.arguments is String) {
        dispatch(call.arguments as String);
      }
    });
  }

  Future<void> checkInitialAction() async {
    _ensureInitialized();
    try {
      final initial = await _channel.invokeMethod<String>('getInitialShortcut');
      if (initial != null && initial.isNotEmpty) {
        dispatch(initial);
      }
    } on MissingPluginException {
      // Expected in unit/widget tests or platforms without quick actions.
    } catch (error) {
      debugPrint('Quick actions unavailable: $error');
    }
  }

  void dispatch(String action) {
    if (action.isEmpty) return;
    _controller.add(action);
  }
}
