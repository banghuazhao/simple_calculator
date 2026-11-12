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
    final compact = MediaQuery.sizeOf(context).height <= 740;
    final transitionDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 160);
    final textColor = model.panelTextColor;

    final mainStyle =
        Theme.of(context).textTheme.displayMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: compact ? 48 : 60,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        const TextStyle();

    final historyStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: textColor,
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: model.panelColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: model.panelBorderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (history.isNotEmpty)
                  Semantics(
                    label: copyCalculation == null
                        ? history
                        : strings.copyCalculation,
                    value: copyCalculation == null ? null : history,
                    button: copyCalculation != null,
                    onTap: copyCalculation,
                    excludeSemantics: true,
                    child: InkWell(
                      excludeFromSemantics: true,
                      borderRadius: BorderRadius.circular(12),
                      onTap: copyCalculation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: AnimatedSwitcher(
                          duration: transitionDuration,
                          child: Align(
                            key: ValueKey(history),
                            alignment: Alignment.centerRight,
                            child: Text(
                              history,
                              style: historyStyle,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Flexible(
                  child: Semantics(
                    label: isError ? strings.error : strings.copyResult,
                    value: isError ? null : formattedCurrent,
                    button: !isError,
                    onTap: copyNumber,
                    excludeSemantics: true,
                    child: InkWell(
                      excludeFromSemantics: true,
                      borderRadius: BorderRadius.circular(12),
                      onTap: copyNumber,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              if (!isError) ...[
                                Icon(
                                  Icons.copy_outlined,
                                  color: textColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: transitionDuration,
                                  child: Align(
                                    key: displayKey,
                                    alignment: Alignment.centerRight,
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
