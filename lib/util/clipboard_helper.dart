import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/input_feedback.dart';

class ClipboardHelper {
  static Future<void> copy(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (error) {
      debugPrint('Clipboard unavailable: $error');
      return;
    }
    if (!context.mounted) return;
    // Feedback is optional; it must not delay successful copy confirmation.
    unawaited(InputFeedback.mediumImpact());
    showMessage(context, S.of(context).copied);
  }

  /// Reads the clipboard and enters it as the current number when it is a
  /// single valid number. Always tells the user what happened.
  static Future<void> paste(BuildContext context) async {
    String? text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } catch (error) {
      debugPrint('Clipboard unavailable: $error');
      if (context.mounted) {
        showMessage(context, S.of(context).clipboardUnavailable);
      }
      return;
    }
    if (!context.mounted) return;
    final strings = S.of(context);
    if (text != null && Processor.paste(text)) {
      unawaited(InputFeedback.lightImpact());
      showMessage(context, strings.pasted);
    } else {
      showMessage(context, strings.invalidPaste);
    }
  }

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
      );
  }
}
