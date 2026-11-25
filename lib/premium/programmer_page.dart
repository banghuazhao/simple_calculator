import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/theme_model.dart';

enum _NumberBase {
  dec(10, 'DEC'),
  hex(16, 'HEX'),
  oct(8, 'OCT'),
  bin(2, 'BIN');

  const _NumberBase(this.radix, this.label);
  final int radix;
  final String label;
}

enum _BitwiseOp {
  none('—'),
  and('AND'),
  or('OR'),
  xor('XOR'),
  not('NOT'),
  shl('<<'),
  shr('>>');

  const _BitwiseOp(this.label);
  final String label;
}

class ProgrammerPage extends StatefulWidget {
  const ProgrammerPage({super.key});

  @override
  State<ProgrammerPage> createState() => _ProgrammerPageState();
}

class _ProgrammerPageState extends State<ProgrammerPage> {
  _NumberBase _base = _NumberBase.dec;
  _BitwiseOp _op = _BitwiseOp.none;
  final _primary = TextEditingController(text: '255');
  final _secondary = TextEditingController(text: '15');

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  int? _parse(String text) {
    final cleaned = text
        .trim()
        .replaceAll('−', '-')
        .replaceAll(RegExp(r'[\s_,]+'), '');
    if (cleaned.isEmpty) return null;
    final negative = cleaned.startsWith('-');
    var body = negative || cleaned.startsWith('+')
        ? cleaned.substring(1)
        : cleaned;
    final prefix = switch (_base) {
      _NumberBase.hex => RegExp(r'^0[xX]'),
      _NumberBase.bin => RegExp(r'^0[bB]'),
      _NumberBase.oct => RegExp(r'^0[oO]'),
      _NumberBase.dec => null,
    };
    if (prefix != null) body = body.replaceFirst(prefix, '');
    if (body.isEmpty) return null;
    return int.tryParse(negative ? '-$body' : body, radix: _base.radix);
  }

  String _formatBase(int value, int radix) {
    final negative = value < 0;
    final raw = BigInt.from(value).abs().toRadixString(radix).toUpperCase();
    if (radix == 2) {
      final padded = raw.padLeft(((raw.length + 3) ~/ 4) * 4, '0');
      final grouped = padded
          .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ')
          .trim();
      return negative ? '-$grouped' : grouped;
    }
    return negative ? '-$raw' : raw;
  }

  int? _compute(int? a, int? b) {
    if (a == null) return null;
    switch (_op) {
      case _BitwiseOp.none:
        return a;
      case _BitwiseOp.not:
        return ~a;
      case _BitwiseOp.and:
        return b == null ? null : a & b;
      case _BitwiseOp.or:
        return b == null ? null : a | b;
      case _BitwiseOp.xor:
        return b == null ? null : a ^ b;
      case _BitwiseOp.shl:
        return b == null || b < 0 || b > 62 ? null : a << b;
      case _BitwiseOp.shr:
        return b == null || b < 0 || b > 62 ? null : a >> b;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final theme = Theme.of(context);
    final ink = model.readableTextColor;
    final border = OutlineInputBorder(borderSide: BorderSide(color: ink));
    final a = _parse(_primary.text);
    final b = _parse(_secondary.text);
    final needsSecond =
        _op != _BitwiseOp.none && _op != _BitwiseOp.not;
    final value = _compute(a, b);

    Widget baseRow(String label, String formatted, String raw) => InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ClipboardHelper.copy(context, raw),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: TextStyle(
                  color: model.panelTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                formatted,
                style: TextStyle(
                  color: model.panelTextColor,
                  fontSize: 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Icon(Icons.copy_outlined, size: 18, color: model.panelTextColor),
          ],
        ),
      ),
    );

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: ink,
          onPrimary: model.backgroundColor,
          secondaryContainer: ink,
          onSecondaryContainer: model.backgroundColor,
          surface: model.panelColor,
          onSurface: model.panelTextColor,
          onSurfaceVariant: ink,
          outline: ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: border,
          enabledBorder: border,
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          backgroundColor: model.backgroundColor,
          foregroundColor: ink,
          title: Text(strings.programmerMode),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    strings.programmerInputBase,
                    style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final base in _NumberBase.values)
                        ChoiceChip(
                          label: Text(base.label),
                          selected: _base == base,
                          onSelected: (_) => setState(() {
                            final parsedA = _parse(_primary.text);
                            final parsedB = _parse(_secondary.text);
                            _base = base;
                            if (parsedA != null) {
                              _primary.text = parsedA
                                  .toRadixString(base.radix)
                                  .toUpperCase();
                            }
                            if (parsedB != null) {
                              _secondary.text = parsedB
                                  .toRadixString(base.radix)
                                  .toUpperCase();
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('programmer-primary-input'),
                    controller: _primary,
                    style: TextStyle(color: ink),
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [LengthLimitingTextInputFormatter(64)],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '${strings.programmerValue} (${_base.label})',
                      errorText: _primary.text.trim().isNotEmpty && a == null
                          ? strings.formulaInvalidInput
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.programmerBitwise,
                    style: TextStyle(color: ink, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final op in _BitwiseOp.values)
                        ChoiceChip(
                          label: Text(op.label),
                          selected: _op == op,
                          onSelected: (_) => setState(() => _op = op),
                        ),
                    ],
                  ),
                  if (needsSecond) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('programmer-secondary-input'),
                      controller: _secondary,
                      style: TextStyle(color: ink),
                      autocorrect: false,
                      enableSuggestions: false,
                      inputFormatters: [LengthLimitingTextInputFormatter(64)],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText:
                            '${strings.programmerSecondValue} (${_base.label})',
                        errorText:
                            _secondary.text.trim().isNotEmpty && b == null
                            ? strings.formulaInvalidInput
                            : null,
                      ),
                    ),
                  ],
                  if (value != null) ...[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: model.panelColor,
                        border: Border.all(color: model.panelBorderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            baseRow(
                              'HEX',
                              _formatBase(value, 16),
                              value.toRadixString(16).toUpperCase(),
                            ),
                            Divider(height: 1, color: model.panelBorderColor),
                            baseRow(
                              'DEC',
                              value.toString(),
                              value.toString(),
                            ),
                            Divider(height: 1, color: model.panelBorderColor),
                            baseRow(
                              'OCT',
                              _formatBase(value, 8),
                              value.toRadixString(8),
                            ),
                            Divider(height: 1, color: model.panelBorderColor),
                            baseRow(
                              'BIN',
                              _formatBase(value, 2),
                              value.toRadixString(2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: () {
                          Processor.useResult(value.toDouble());
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(strings.reuseResult),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
