import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/key_symbol.dart';

class _CalculatorKeyIntent extends Intent {
  const _CalculatorKeyIntent(this.symbol);
  final KeySymbol symbol;
}

class _CalculatorUndoIntent extends Intent {
  const _CalculatorUndoIntent();
}

class _CalculatorPasteIntent extends Intent {
  const _CalculatorPasteIntent();
}

class _CalculatorAction<T extends Intent> extends Action<T> {
  _CalculatorAction({required this.isAvailable, required this.callback});

  final bool Function() isAvailable;
  final void Function(T) callback;

  @override
  bool isEnabled(T intent) => isAvailable();

  @override
  Object? invoke(T intent) {
    callback(intent);
    return null;
  }
}

/// Keyboard input follows the same processor path as the on-screen keypad.
class CalculatorShortcuts extends StatefulWidget {
  const CalculatorShortcuts({
    super.key,
    required this.child,
    required this.onKey,
    required this.onUndo,
    this.onPaste,
  });

  final Widget child;
  final ValueChanged<KeySymbol> onKey;
  final VoidCallback onUndo;
  final VoidCallback? onPaste;

  @override
  State<CalculatorShortcuts> createState() => _CalculatorShortcutsState();

  static final Map<ShortcutActivator, Intent> _bindings = _createBindings();

  static Map<ShortcutActivator, Intent> _createBindings() {
    final bindings = <ShortcutActivator, Intent>{};
    const digits = [
      Keys.zero,
      Keys.one,
      Keys.two,
      Keys.three,
      Keys.four,
      Keys.five,
      Keys.six,
      Keys.seven,
      Keys.eight,
      Keys.nine,
    ];
    const digitKeys = [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = [
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];
    for (var i = 0; i < digits.length; i++) {
      for (final key in [digitKeys[i], numpadKeys[i]]) {
        bindings[SingleActivator(key, includeRepeats: false)] =
            _CalculatorKeyIntent(digits[i]);
      }
      bindings[CharacterActivator('$i', includeRepeats: false)] =
          _CalculatorKeyIntent(digits[i]);
    }
    final keys = <LogicalKeyboardKey, KeySymbol>{
      LogicalKeyboardKey.enter: Keys.equals,
      LogicalKeyboardKey.numpadEnter: Keys.equals,
      LogicalKeyboardKey.equal: Keys.equals,
      LogicalKeyboardKey.backspace: Keys.back,
      LogicalKeyboardKey.escape: Keys.clear,
      LogicalKeyboardKey.period: Keys.decimal,
      LogicalKeyboardKey.minus: Keys.subtract,
      LogicalKeyboardKey.slash: Keys.divide,
      LogicalKeyboardKey.numpadAdd: Keys.add,
      LogicalKeyboardKey.numpadSubtract: Keys.subtract,
      LogicalKeyboardKey.numpadMultiply: Keys.multiply,
      LogicalKeyboardKey.numpadDivide: Keys.divide,
      LogicalKeyboardKey.numpadDecimal: Keys.decimal,
    };
    for (final entry in keys.entries) {
      bindings[SingleActivator(entry.key, includeRepeats: false)] =
          _CalculatorKeyIntent(entry.value);
    }
    for (final entry in const <String, KeySymbol>{
      '+': Keys.add,
      '-': Keys.subtract,
      '*': Keys.multiply,
      '/': Keys.divide,
      '%': Keys.percent,
      '=': Keys.equals,
      '.': Keys.decimal,
    }.entries) {
      bindings[CharacterActivator(entry.key, includeRepeats: false)] =
          _CalculatorKeyIntent(entry.value);
    }
    bindings[const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          includeRepeats: false,
        )] =
        const _CalculatorUndoIntent();
    bindings[const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          includeRepeats: false,
        )] =
        const _CalculatorUndoIntent();
    for (final control in [true, false]) {
      bindings[SingleActivator(
        LogicalKeyboardKey.keyV,
        control: control,
        meta: !control,
        includeRepeats: false,
      )] = const _CalculatorPasteIntent();
    }
    return bindings;
  }
}

class _CalculatorShortcutsState extends State<CalculatorShortcuts> {
  final FocusNode _inputFocus = FocusNode(debugLabel: 'Calculator input');

  @override
  void dispose() {
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canHandle() {
      if (ModalRoute.of(context)?.isCurrent != true) return false;
      // Preserve normal editing shortcuts if a text input is ever added here.
      final focusContext = FocusManager.instance.primaryFocus?.context;
      return focusContext == null ||
          (focusContext.widget is! EditableText &&
              focusContext.findAncestorWidgetOfExactType<EditableText>() ==
                  null);
    }

    return Shortcuts(
      shortcuts: CalculatorShortcuts._bindings,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CalculatorKeyIntent: _CalculatorAction<_CalculatorKeyIntent>(
            isAvailable: canHandle,
            callback: (intent) {
              _inputFocus.requestFocus();
              widget.onKey(intent.symbol);
            },
          ),
          _CalculatorUndoIntent: _CalculatorAction<_CalculatorUndoIntent>(
            isAvailable: canHandle,
            callback: (_) {
              _inputFocus.requestFocus();
              widget.onUndo();
            },
          ),
          _CalculatorPasteIntent: _CalculatorAction<_CalculatorPasteIntent>(
            isAvailable: () => widget.onPaste != null && canHandle(),
            callback: (_) {
              _inputFocus.requestFocus();
              widget.onPaste!();
            },
          ),
        },
        child: Focus(
          focusNode: _inputFocus,
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }
}
