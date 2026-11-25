import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/theme_model.dart';

class Display extends StatelessWidget {
  const Display({
    super.key,
    required this.current,
    required this.history,
    this.isResult = false,
    this.preview,
    this.leftOperand,
    this.rightOperand,
    this.binaryOperator,
    this.rightOperandIsPercent = false,
    this.onCorrectOperand,
    this.onBackspace,
    this.onPaste,
  });

  final String current;
  final String history;
  final bool isResult;
  final String? preview;
  final OperandEdit? leftOperand;
  final OperandEdit? rightOperand;
  final String? binaryOperator;
  final bool rightOperandIsPercent;
  final ValueChanged<OperandEdit>? onCorrectOperand;
  final VoidCallback? onBackspace;
  final VoidCallback? onPaste;

  String _formatForDisplay(String s) =>
      InputSettings.instance.formatDisplayNumber(s);

  Widget _operand(OperandEdit operand, String label, TextStyle style) {
    final percent =
        operand.position == OperandPosition.right && rightOperandIsPercent;
    final value = '${_formatForDisplay(operand.display)}${percent ? '%' : ''}';
    return Flexible(
      child: Tooltip(
        message: label,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: style.color,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.standard,
            textStyle: style.copyWith(decoration: TextDecoration.underline),
          ),
          onPressed: () => onCorrectOperand!(operand),
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
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

    final previewStyle =
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: model.highContrastEnabled
              ? textColor
              : textColor.withValues(alpha: 0.65),
          fontSize: compact ? 15 : 18,
          fontFeatures: const [FontFeature.tabularFigures()],
        ) ??
        const TextStyle();

    return ListenableBuilder(
      listenable: InputSettings.instance,
      builder: (context, _) {
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
        final left = leftOperand;
        final right = rightOperand;
        final operator = binaryOperator;
        final showPreview =
            preview != null && !isResult && !isError && preview != current;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: onBackspace == null
              ? null
              : (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() >= 150) {
                    unawaited(InputFeedback.lightImpact());
                    onBackspace!();
                  }
                },
          child: Padding(
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
                      if (left != null &&
                          operator != null &&
                          onCorrectOperand != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _operand(
                              left,
                              strings.editFirstOperand,
                              historyStyle,
                            ),
                            Text(operator, style: historyStyle),
                            if (right != null)
                              _operand(
                                right,
                                strings.editSecondOperand,
                                historyStyle,
                              ),
                            if (copyCalculation != null) ...[
                              Text('=', style: historyStyle),
                              IconButton(
                                tooltip: strings.copyCalculation,
                                color: textColor,
                                onPressed: copyCalculation,
                                icon: const Icon(Icons.copy_outlined, size: 18),
                              ),
                            ],
                          ],
                        )
                      else if (history.isNotEmpty)
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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
                        child: Row(
                          children: [
                            if (onPaste != null)
                              IconButton(
                                tooltip: strings.pasteNumber,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: onPaste,
                                icon: Icon(
                                  Icons.content_paste_outlined,
                                  color: textColor,
                                  size: 20,
                                ),
                              ),
                            Expanded(
                              child: Semantics(
                                label: isError
                                    ? strings.error
                                    : strings.copyResult,
                                value: isError ? null : formattedCurrent,
                                button: !isError,
                                onTap: copyNumber,
                                excludeSemantics: true,
                                child: InkWell(
                                  excludeFromSemantics: true,
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: copyNumber,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
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
                                                alignment:
                                                    Alignment.centerRight,
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
                      if (showPreview)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '= ${_formatForDisplay(preview!)}',
                              key: const ValueKey('display-live-preview'),
                              style: previewStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
