import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/premium/scientific_history.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';

class ScientificHistoryPage extends StatelessWidget {
  const ScientificHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = context.watch<ThemeModel>();
    final textColor = theme.panelTextColor;
    final entries = ScientificHistory.instance.entries;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        foregroundColor: theme.readableTextColor,
        title: Text(strings.scientificHistory),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      strings.noCalculationsYet,
                      style: TextStyle(color: theme.readableTextColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        color: theme.panelColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.panelBorderColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Semantics(
                          button: true,
                          hint: strings.historyEditCalculation,
                          child: ListTile(
                            textColor: textColor,
                            iconColor: textColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              entry.expression,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '= ${Processor.formatResult(entry.result)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  entry.degrees
                                      ? strings.scientificDegrees
                                      : strings.scientificRadians,
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => Navigator.of(context).pop(entry),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
