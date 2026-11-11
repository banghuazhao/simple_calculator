import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/theme_model.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final strings = S.of(context);
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: model.textColor1,
      height: 1.5,
    );
    final headingStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: model.textColor1,
      fontWeight: FontWeight.w600,
    );
    final keyStyle = bodyStyle?.copyWith(fontWeight: FontWeight.w600);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        header: true,
        child: Text(text, style: headingStyle),
      ),
    );

    Widget paragraph(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: bodyStyle),
    );

    Widget shortcut(String keys, String description) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(keys, style: keyStyle),
          const SizedBox(height: 4),
          Text(description, style: bodyStyle),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: model.backgroundColor,
      appBar: AppBar(
        backgroundColor: model.backgroundColor,
        elevation: 0,
        leading: BackButton(color: model.textColor1),
        title: Text(
          strings.helpAndShortcuts,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: model.textColor1),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading(strings.helpBasics),
                    paragraph(strings.helpCopy),
                    paragraph(strings.helpCopyHistory),
                    paragraph(strings.helpUndo),
                    paragraph(strings.helpHistory),
                    paragraph(strings.helpPaste),
                    const SizedBox(height: 8),
                    heading(strings.helpKeyboard),
                    shortcut('0–9', strings.shortcutNumbers),
                    shortcut('+  -  *  /  %  .', strings.shortcutOperators),
                    shortcut('Enter / =', strings.shortcutEquals),
                    shortcut('Backspace', strings.shortcutBackspace),
                    shortcut('Escape', strings.shortcutClear),
                    shortcut('Ctrl / Cmd + Z', strings.shortcutUndo),
                    shortcut('Ctrl / Cmd + V', strings.shortcutPaste),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
