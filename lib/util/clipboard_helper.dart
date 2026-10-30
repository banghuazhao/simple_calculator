import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_calculator/generated/l10n.dart';
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).copied,
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
