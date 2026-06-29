import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/util/ThemeModel.dart';

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

  /// Formats a number string with thousand separators for display only.
  String _formatForDisplay(String s) {
    if (s == 'Error') return s;
    if (s.contains('e') || s.contains('E')) return s; // scientific notation

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
    final model = Provider.of<ThemeModel>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double inset = screenWidth > 600 ? (screenWidth - 560) / 2 : 24.0;
    final bool compact = screenHeight <= 740;

    final Color textColor = model.textColor1;
    final Color historyColor = textColor.withValues(alpha: 0.5);

    final mainStyle = Theme.of(context).textTheme.displayMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w300,
              fontSize: compact ? 48 : 60,
            ) ??
        const TextStyle();

    final historyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: historyColor,
              fontSize: compact ? 14 : 16,
            ) ??
        const TextStyle();

    final formattedCurrent = _formatForDisplay(current);
    // Unique key: animate when result appears or when error, not on every digit
    final displayKey = isResult
        ? ValueKey('result_$formattedCurrent')
        : const ValueKey('input');

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, compact ? 8 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // History / equation line — fades in/out
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
          // Main number — slides up when result appears
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: Align(
              key: displayKey,
              alignment: Alignment.centerRight,
              child: AutoSizeText(
                formattedCurrent,
                style: mainStyle,
                maxLines: 1,
                textAlign: TextAlign.right,
                minFontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
