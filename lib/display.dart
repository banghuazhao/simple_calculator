import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/theme_model.dart';

class Display extends StatelessWidget {
  const Display({
    super.key,
    required this.current,
    required this.history,
    this.isResult = false,
  });

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

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = Provider.of<ThemeModel>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double inset = screenWidth > 600 ? (screenWidth - 560) / 2 : 24.0;
    final bool compact = screenHeight <= 740;

    final Color textColor = model.textColor1;
    final Color historyColor = model.secondaryTextColor;

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
    final copyNumber = isError
        ? null
        : () => ClipboardHelper.copyNumber(context, current);
    final copyCalculation = isResult && !isError && history.isNotEmpty
        ? () => ClipboardHelper.copy(context, '$history $current')
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, compact ? 8 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            label: copyCalculation == null ? history : strings.copyCalculation,
            value: copyCalculation == null ? null : history,
            button: copyCalculation != null,
            onTap: copyCalculation,
            excludeSemantics: true,
            child: GestureDetector(
              excludeFromSemantics: true,
              onTap: copyCalculation,
              child: AnimatedSwitcher(
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
            ),
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
              onTap: copyNumber,
              excludeSemantics: true,
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: copyNumber,
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
