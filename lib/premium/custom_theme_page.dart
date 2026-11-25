import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/theme_model.dart';

class CustomThemePage extends StatefulWidget {
  const CustomThemePage({super.key});

  @override
  State<CustomThemePage> createState() => _CustomThemePageState();
}

class _CustomThemePageState extends State<CustomThemePage> {
  static const _backgroundSwatches = [
    Color(0xff1E2430),
    Color(0xff121212),
    Color(0xff1B2838),
    Color(0xff2B213A),
    Color(0xff182C25),
    Color(0xffF7F4EF),
    Color(0xffFFFFFF),
    Color(0xffEAF2F8),
    Color(0xffFDF2F8),
    Color(0xffECFDF5),
  ];

  static const _keySwatches = [
    Color(0xff323B4D),
    Color(0xff2A2A2A),
    Color(0xff4B5563),
    Color(0xff3B82F6),
    Color(0xff10B981),
    Color(0xffF59E0B),
    Color(0xffEF4444),
    Color(0xff8B5CF6),
    Color(0xffEC4899),
    Color(0xff14B8A6),
    Color(0xffE5E7EB),
    Color(0xffFDE68A),
  ];

  late Color _background;
  late Color _button1;
  late Color _button2;
  late Color _button3;

  @override
  void initState() {
    super.initState();
    final palette = context.read<ThemeModel>().customPalette;
    _background = palette.background;
    _button1 = palette.button1;
    _button2 = palette.button2;
    _button3 = palette.button3;
  }

  void _apply() {
    context.read<ThemeModel>().setCustomPalette(
      CustomThemePalette(
        background: _background,
        button1: _button1,
        button2: _button2,
        button3: _button3,
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _swatchSection(
    String title,
    List<Color> swatches,
    Color selected,
    ValueChanged<Color> onSelect,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in swatches)
              Semantics(
                button: true,
                selected: color.toARGB32() == selected.toARGB32(),
                label: title,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => onSelect(color)),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.toARGB32() == selected.toARGB32()
                            ? textColor
                            : textColor.withValues(alpha: 0.25),
                        width: color.toARGB32() == selected.toARGB32() ? 3 : 1,
                      ),
                    ),
                    child: color.toARGB32() == selected.toARGB32()
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: ThemeModel.readableOn(color, Colors.white),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final ink = model.readableTextColor;
    final previewText = ThemeModel.readableOn(_background, Colors.white);
    final previewKeyText1 = ThemeModel.readableOn(_button1, Colors.white);
    final previewKeyText2 = ThemeModel.readableOn(_button2, Colors.white);
    final previewKeyText3 = ThemeModel.readableOn(_button3, Colors.white);
    final minContrast = [
      ThemeModel.contrastRatio(_background, previewText),
      ThemeModel.contrastRatio(_button1, previewKeyText1),
      ThemeModel.contrastRatio(_button2, previewKeyText2),
      ThemeModel.contrastRatio(_button3, previewKeyText3),
    ].reduce((a, b) => a < b ? a : b);

    Widget previewKey(String label, Color bg, Color fg) => Expanded(
      child: Container(
        height: 44,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: model.backgroundColor,
      appBar: AppBar(
        backgroundColor: model.backgroundColor,
        foregroundColor: ink,
        title: Text(strings.customTheme),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: model.panelBorderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '1,234.56',
                            style: TextStyle(
                              color: previewText,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            previewKey('C', _button3, previewKeyText3),
                            previewKey('±', _button3, previewKeyText3),
                            previewKey('%', _button3, previewKeyText3),
                            previewKey('÷', _button2, previewKeyText2),
                          ],
                        ),
                        Row(
                          children: [
                            previewKey('7', _button1, previewKeyText1),
                            previewKey('8', _button1, previewKeyText1),
                            previewKey('9', _button1, previewKeyText1),
                            previewKey('×', _button2, previewKeyText2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.verified_outlined, size: 18, color: ink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${strings.customThemeContrastGood} (${minContrast.toStringAsFixed(1)}:1)',
                        style: TextStyle(color: ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _swatchSection(
                  strings.customThemeBackground,
                  _backgroundSwatches,
                  _background,
                  (c) => _background = c,
                  ink,
                ),
                const SizedBox(height: 16),
                _swatchSection(
                  strings.customThemeNumberKeys,
                  _keySwatches,
                  _button1,
                  (c) => _button1 = c,
                  ink,
                ),
                const SizedBox(height: 16),
                _swatchSection(
                  strings.customThemeOperatorKeys,
                  _keySwatches,
                  _button2,
                  (c) => _button2 = c,
                  ink,
                ),
                const SizedBox(height: 16),
                _swatchSection(
                  strings.customThemeFunctionKeys,
                  _keySwatches,
                  _button3,
                  (c) => _button3 = c,
                  ink,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: model.backgroundColor,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: _apply,
                  child: Text(strings.customThemeApply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
