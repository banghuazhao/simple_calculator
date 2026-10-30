import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/generated/l10n.dart';

Map<String, String> calculatorMessages(S strings) => {
  'history': strings.history,
  'clearHistoryTitle': strings.clearHistoryTitle,
  'clearHistoryMessage': strings.clearHistoryMessage,
  'cancel': strings.cancel,
  'clear': strings.clear,
  'noCalculationsYet': strings.noCalculationsYet,
  'copied': strings.copied,
  'settings': strings.settings,
  'undo': strings.undo,
  'clearInput': strings.clearInput,
  'changeSign': strings.changeSign,
  'percent': strings.percent,
  'divide': strings.divide,
  'multiply': strings.multiply,
  'subtract': strings.subtract,
  'add': strings.add,
  'equals': strings.equals,
  'decimalPoint': strings.decimalPoint,
  'backspace': strings.backspace,
  'copyResult': strings.copyResult,
  'error': strings.error,
  'reuseResult': strings.reuseResult,
  'deleteCalculation': strings.deleteCalculation,
  'copyCalculation': strings.copyCalculation,
  'inputSettings': strings.inputSettings,
  'hapticFeedback': strings.hapticFeedback,
  'hapticFeedbackDescription': strings.hapticFeedbackDescription,
  'shakeToUndo': strings.shakeToUndo,
  'shakeToUndoDescription': strings.shakeToUndoDescription,
};

void main() {
  const expectedHistory = {'en': 'History', 'zh': '历史记录', 'zh_HK': '歷史記錄'};

  for (final locale in S.delegate.supportedLocales) {
    test('calculator messages load completely for $locale', () async {
      final strings = await S.load(locale);
      final messages = calculatorMessages(strings);
      final source =
          jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;

      expect(strings.history, expectedHistory[locale.toString()]);
      for (final message in messages.entries) {
        expect(source[message.key], isA<String>(), reason: message.key);
        expect(message.value, isNotEmpty, reason: message.key);
        expect(message.value, source[message.key], reason: message.key);
      }
    });
  }
}
