import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/history_expression.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/history_storage.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/theme_model.dart';

enum _HistoryEntryAction { edit, pin, name, delete }

class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key});

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  // Match the whole numeric token so malformed grouping stays literal.
  static final _searchNumber = RegExp(r'[\d.,]+(?:e[+-]?[\d.,]*)?');
  static final _groupedNumber = RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d*)?$');

  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _deletionRevision = 0;

  @override
  void dispose() {
    _deletionRevision++;
    _search.dispose();
    super.dispose();
  }

  String _searchable(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-');

  Future<void> _edit(BuildContext sheetContext, HistoryEntry entry) async {
    final applied = await showDialog<bool>(
      context: sheetContext,
      builder: (_) => _HistoryEditor(expression: entry.expression),
    );
    if (applied != true || !mounted || !sheetContext.mounted) return;
    _deletionRevision++;
    Navigator.of(sheetContext).pop();
  }

  void _pin(BuildContext context, HistoryEntry entry) {
    if (!entry.isPinned && !Processor.canPinHistoryEntry) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).historyPinLimit)));
      return;
    }
    if (Processor.setHistoryPinned(entry.id, !entry.isPinned)) {
      setState(() {});
    }
  }

  Future<void> _name(BuildContext context, HistoryEntry entry) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _HistoryNameDialog(name: entry.name),
    );
    if (!mounted || name == null) return;
    if (Processor.renameHistoryEntry(entry.id, name)) setState(() {});
  }

  Future<void> _clearHistory(BuildContext sheetContext) async {
    final strings = S.of(sheetContext);
    final confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.clearHistoryTitle),
        content: Text(strings.clearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.clear),
          ),
        ],
      ),
    );
    if (!mounted || !sheetContext.mounted || confirmed != true) return;
    _deletionRevision++;
    final messenger = ScaffoldMessenger.of(sheetContext);
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar();
    Processor.clearHistory();
    _search.clear();
    setState(() => _query = '');
    unawaited(InputFeedback.mediumImpact());
  }

  void _delete(BuildContext sheetContext, HistoryEntry entry) {
    final deletion = Processor.removeHistoryEntry(entry.id);
    if (deletion == null) return;
    final revision = ++_deletionRevision;
    setState(() {});
    unawaited(InputFeedback.lightImpact());
    final strings = S.of(sheetContext);
    final messenger = ScaffoldMessenger.of(sheetContext);
    messenger.clearSnackBars();
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.historyDeleted),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () {
            if (!mounted || revision != _deletionRevision) return;
            _deletionRevision++;
            if (Processor.restoreHistoryEntry(deletion)) {
              setState(() {});
              unawaited(InputFeedback.lightImpact());
            }
          },
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, HistoryEntry entry, ThemeModel model) {
    final strings = S.of(context);
    final textColor = model.textColor1;
    final name = entry.name;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: Icon(
          Icons.delete_outline,
          semanticLabel: strings.deleteCalculation,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _delete(context, entry),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              hint: strings.reuseResult,
              child: InkWell(
                onTap: () {
                  _deletionRevision++;
                  Processor.setFromHistory(
                    entry.result,
                    preciseResult: entry.preciseResult,
                  );
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (entry.isPinned || name != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (entry.isPinned)
                                Icon(
                                  Icons.push_pin,
                                  size: 16,
                                  color: textColor,
                                  semanticLabel: strings.historyPinned,
                                ),
                              if (name != null) ...[
                                if (entry.isPinned) const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      Text(
                        entry.equation,
                        style: TextStyle(
                          color: model.secondaryTextColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.result,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: strings.copyCalculation,
            onPressed: () => ClipboardHelper.copy(
              context,
              '${entry.equation} ${entry.result}',
            ),
            icon: Icon(Icons.copy_outlined, color: textColor),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MergeSemantics(
              child: Semantics(
                value: entry.equation,
                child: PopupMenuButton<_HistoryEntryAction>(
                  tooltip: strings.historyEntryActions,
                  iconColor: textColor,
                  color: model.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  shape: model.highContrastEnabled
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: BorderSide(color: textColor),
                        )
                      : null,
                  requestFocus: true,
                  onSelected: (action) {
                    if (!mounted || !context.mounted) return;
                    switch (action) {
                      case _HistoryEntryAction.edit:
                        unawaited(_edit(context, entry));
                      case _HistoryEntryAction.pin:
                        _pin(context, entry);
                      case _HistoryEntryAction.name:
                        unawaited(_name(context, entry));
                      case _HistoryEntryAction.delete:
                        _delete(context, entry);
                    }
                  },
                  itemBuilder: (_) => [
                    for (final (action, label) in [
                      (
                        _HistoryEntryAction.edit,
                        strings.historyEditCalculation,
                      ),
                      (
                        _HistoryEntryAction.pin,
                        entry.isPinned
                            ? strings.historyUnpinCalculation
                            : strings.historyPinCalculation,
                      ),
                      (
                        _HistoryEntryAction.name,
                        name == null
                            ? strings.historyNameCalculation
                            : strings.historyRenameCalculation,
                      ),
                      (_HistoryEntryAction.delete, strings.deleteCalculation),
                    ])
                      PopupMenuItem(
                        value: action,
                        child: Text(label, style: TextStyle(color: textColor)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contents(BuildContext context, ThemeModel model) {
    final strings = S.of(context);
    final entries = Processor.historyLog;
    final query = _searchable(_query);
    final numericQuery = query.replaceAllMapped(_searchNumber, (match) {
      final number = match[0]!;
      return _groupedNumber.hasMatch(number)
          ? number.replaceAll(',', '')
          : number;
    });
    final filtered = query.isEmpty
        ? entries
        : entries
              .where(
                (entry) =>
                    _searchable(
                      '${entry.equation} ${entry.result}',
                    ).contains(numericQuery) ||
                    _searchable(entry.name ?? '').contains(query),
              )
              .toList();
    final textColor = model.textColor1;
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: model.handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  strings.history,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                );
                final actions = <Widget>[
                  IconButton(
                    key: const ValueKey('history-copy-bulk'),
                    tooltip: query.isEmpty
                        ? strings.copyAllHistory
                        : strings.copyMatchingHistory,
                    onPressed: filtered.isEmpty
                        ? null
                        : () => ClipboardHelper.copy(
                            context,
                            filtered
                                .map(
                                  (entry) =>
                                      '${entry.equation} ${entry.result}',
                                )
                                .join('\n'),
                          ),
                    color: textColor,
                    disabledColor: textColor.withValues(alpha: 0.35),
                    icon: const Icon(Icons.copy_all_outlined),
                  ),
                  IconButton(
                    key: const ValueKey('history-copy-tsv'),
                    tooltip: strings.historyCopyAsTsv,
                    onPressed: filtered.isEmpty
                        ? null
                        : () => ClipboardHelper.copy(
                            context,
                            filtered
                                .map((entry) {
                                  final expression =
                                      HistoryExpression.fromEquation(
                                        entry.equation,
                                      );
                                  return '$expression\t${entry.result}';
                                })
                                .join('\n'),
                          ),
                    color: textColor,
                    disabledColor: textColor.withValues(alpha: 0.35),
                    icon: const Icon(Icons.table_chart_outlined),
                  ),
                  if (entries.isNotEmpty)
                    TextButton(
                      onPressed: () => _clearHistory(context),
                      child: Text(
                        query.isEmpty ? strings.clear : strings.clearAllHistory,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                    ),
                ];
                if (MediaQuery.textScalerOf(context).scale(15) > 24 ||
                    (constraints.maxWidth < 320 && query.isNotEmpty)) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: actions,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    ...actions,
                  ],
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              key: const ValueKey('history-search'),
              controller: _search,
              style: TextStyle(color: textColor),
              textInputAction: TextInputAction.search,
              inputFormatters: [LengthLimitingTextInputFormatter(256)],
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: strings.searchHistory,
                labelStyle: TextStyle(color: textColor),
                prefixIcon: Icon(Icons.search, color: textColor),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: strings.clearSearch,
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(Icons.close, color: textColor),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  query.isEmpty
                      ? strings.noCalculationsYet
                      : strings.noHistoryMatches,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: model.mutedTextColor, fontSize: 16),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              findItemIndexCallback: (key) {
                final index = filtered.indexWhere(
                  (entry) => ValueKey(entry.id) == key,
                );
                return index < 0 ? null : index;
              },
              itemBuilder: (_, index) =>
                  _entry(context, filtered[index], model),
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: model.dividerColor,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final media = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = max(
          0.0,
          min(constraints.maxHeight, media.size.height) -
              media.viewInsets.bottom,
        );
        final height = min(
          available,
          media.viewInsets.bottom > 0 ? available : media.size.height * 0.65,
        );
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: SizedBox(
            height: height,
            child: ScaffoldMessenger(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: model.backgroundColor,
                body: SafeArea(
                  top: false,
                  child: Builder(
                    builder: (context) => _contents(context, model),
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

class _HistoryNameDialog extends StatefulWidget {
  const _HistoryNameDialog({required this.name});

  final String? name;

  @override
  State<_HistoryNameDialog> createState() => _HistoryNameDialogState();
}

class _HistoryNameDialogState extends State<_HistoryNameDialog> {
  final _form = GlobalKey<FormState>();
  late String _name = widget.name ?? '';

  void _save() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (_form.currentState?.validate() == true) {
      Navigator.of(context).pop(HistoryStorage.normalizeName(_name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final textStyle = TextStyle(color: model.readableTextColor);
    return AlertDialog(
      scrollable: true,
      backgroundColor: model.backgroundColor,
      title: Text(
        widget.name == null
            ? strings.historyNameCalculation
            : strings.historyRenameCalculation,
        style: textStyle,
      ),
      content: Form(
        key: _form,
        child: TextFormField(
          key: const ValueKey('history-calculation-name'),
          initialValue: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          style: textStyle,
          onChanged: (value) => _name = value,
          onFieldSubmitted: (_) => _save(),
          validator: (value) =>
              HistoryStorage.normalizeName(value ?? '').length >
                  HistoryStorage.maxNameLength
              ? strings.historyNameTooLong
              : null,
          decoration: InputDecoration(
            labelText: strings.historyCalculationName,
            labelStyle: textStyle,
            errorStyle: textStyle,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel, style: textStyle),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: model.readableTextColor,
            foregroundColor: model.backgroundColor,
          ),
          onPressed: _save,
          child: Text(strings.formulaSave),
        ),
      ],
    );
  }
}

class _HistoryEditor extends StatefulWidget {
  const _HistoryEditor({required this.expression});

  final String expression;

  @override
  State<_HistoryEditor> createState() => _HistoryEditorState();
}

class _HistoryEditorState extends State<_HistoryEditor> {
  late final _expression = TextEditingController(text: widget.expression);
  bool _hasError = false;

  @override
  void dispose() {
    _expression.dispose();
    super.dispose();
  }

  void _calculate() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (Processor.rerunHistory(_expression.text)) {
      Navigator.of(context).pop(true);
    } else if (!_hasError) {
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final textStyle = TextStyle(color: model.textColor1);
    return AlertDialog(
      scrollable: true,
      backgroundColor: model.backgroundColor,
      title: Text(strings.historyEditCalculation, style: textStyle),
      content: TextField(
        key: const ValueKey('history-editor-expression'),
        controller: _expression,
        autofocus: true,
        minLines: 1,
        maxLines: 4,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        textInputAction: TextInputAction.done,
        style: textStyle,
        inputFormatters: [
          LengthLimitingTextInputFormatter(HistoryExpression.maxLength),
        ],
        onChanged: (_) {
          if (_hasError) setState(() => _hasError = false);
        },
        onSubmitted: (_) => _calculate(),
        decoration: InputDecoration(
          labelText: strings.scientificExpression,
          labelStyle: textStyle,
          helperText: strings.historyExpressionHelp,
          helperStyle: textStyle,
          helperMaxLines: 3,
          errorText: _hasError ? strings.historyInvalidExpression : null,
          errorStyle: textStyle,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel, style: textStyle),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: model.textColor1,
            foregroundColor: model.backgroundColor,
          ),
          onPressed: _calculate,
          child: Text(strings.scientificEvaluate),
        ),
      ],
    );
  }
}
