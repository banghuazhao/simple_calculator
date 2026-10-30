import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/theme_model.dart';

class Display extends StatelessWidget {
  const Display({
    Key? key,
    required this.current,
    required this.history,
    this.isResult = false,
  }) : super(key: key);

  final String current;
  final String history;
  final bool isResult;

  String _formatForDisplay(String s) {
    if (s == 'Error') return s;
    if (s.contains('e') || s.contains('E')) return s;

    final isNeg = s.startsWith('-');
    final abs = isNeg ? s.substring(1) : s;
    final dotIndex = abs.indexOf('.');
    final intStr = dotIndex >= 0 ? abs.substring(0, dotIndex) : abs;
    final decStr = dotIndex >= 0 ? abs.substring(dotIndex) : '';

    final buf = StringBuffer();
    for (int i = 0; i < intStr.length; i++) {
      if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(',');
      buf.write(intStr[i]);
    }

    return (isNeg ? '-' : '') + buf.toString() + decStr;
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    if (current == 'Error') return;
    try {
      await Clipboard.setData(ClipboardData(text: current));
    } catch (error) {
      debugPrint('Clipboard unavailable: $error');
      return;
    }
    try {
      await HapticFeedback.mediumImpact();
    } catch (error) {
      debugPrint('Copy feedback unavailable: $error');
    }
    if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = Provider.of<ThemeModel>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double inset = screenWidth > 600 ? (screenWidth - 560) / 2 : 24.0;
    final bool compact = screenHeight <= 740;

    final Color textColor = model.textColor1;
    final Color historyColor = textColor.withValues(alpha: 0.5);

    final mainStyle =
        Theme.of(context).textTheme.displayMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w300,
          fontSize: compact ? 48 : 60,
        ) ??
        const TextStyle();

    final historyStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: historyColor,
          fontSize: compact ? 14 : 16,
        ) ??
        const TextStyle();

    final isError = current == 'Error';
    final formattedCurrent = isError
        ? strings.error
        : _formatForDisplay(current);
    final displayKey = isResult
        ? ValueKey('result_$formattedCurrent')
        : const ValueKey('input');

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, compact ? 8 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // History / equation line
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: history.isNotEmpty
                ? Align(
                    key: ValueKey(history),
                    alignment: Alignment.centerRight,
                    child: Text(
                      history,
                      style: historyStyle,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-history')),
          ),
          SizedBox(height: compact ? 2 : 4),
          // Main number — tap to copy
          // Bound the result height so large system text can fit above the keypad.
          Flexible(
            fit: FlexFit.loose,
            child: Semantics(
              label: isError ? strings.error : strings.copyResult,
              value: isError ? null : formattedCurrent,
              button: !isError,
              onTap: isError ? null : () => _copyToClipboard(context),
              excludeSemantics: true,
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: isError ? null : () => _copyToClipboard(context),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: Align(
                    key: displayKey,
                    alignment: Alignment.bottomRight,
                    heightFactor: 1,
                    child: AutoSizeText(
                      formattedCurrent,
                      style: mainStyle,
                      maxLines: 1,
                      textAlign: TextAlign.right,
                      minFontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
