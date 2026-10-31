import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/theme_model.dart';

class HistorySheet extends StatefulWidget {
  const HistorySheet({super.key});

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
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
                  Processor.setFromHistory(entry.result);
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
                      Text(
                        entry.equation,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: strings.copyCalculation,
              onPressed: () => ClipboardHelper.copy(
                context,
                '${entry.equation} ${entry.result}',
              ),
              icon: Icon(Icons.copy_outlined, color: textColor),
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
    final filtered = query.isEmpty
        ? entries
        : entries
              .where(
                (entry) => _searchable(
                  '${entry.equation} ${entry.result}',
                ).contains(query),
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
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.history,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: () => _clearHistory(context),
                    child: Text(
                      query.isEmpty ? strings.clear : strings.clearAllHistory,
                      style: TextStyle(color: textColor, fontSize: 15),
                    ),
                  ),
              ],
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
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.65),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              itemBuilder: (_, index) =>
                  _entry(context, filtered[index], model),
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: textColor.withValues(alpha: 0.08),
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
