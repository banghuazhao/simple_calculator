import 'dart:async';

import 'package:simple_calculator/calculator_key.dart';

class KeyEvent {
  KeyEvent(this.key);
  final CalculatorKey key;
}

abstract class KeyController {
  static final StreamController<KeyEvent> _controller =
      StreamController<KeyEvent>.broadcast();

  static StreamSubscription<KeyEvent> listen(void Function(KeyEvent) handler) =>
      _controller.stream.listen(handler);
  static void fire(KeyEvent event) => _controller.add(event);

  static Future<void> dispose() => _controller.close();
}
