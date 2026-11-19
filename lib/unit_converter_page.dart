import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/measurement_units.dart';
import 'package:simple_calculator/util/theme_model.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final _amount = TextEditingController();
  MeasurementQuantity _quantity = MeasurementQuantity.length;
  MeasurementUnit _from = MeasurementUnit.meter;
  MeasurementUnit _to = MeasurementUnit.foot;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setQuantity(MeasurementQuantity quantity) {
    if (_quantity == quantity) return;
    setState(() {
      _quantity = quantity;
      _from = quantity.units.first;
      _to = quantity.units[1];
    });
  }

  void _swap(double? result) {
    setState(() {
      final previousFrom = _from;
      _from = _to;
      _to = previousFrom;
      if (result != null && result.isFinite) {
        final text = result.toString();
        _amount.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  Widget _unitField(
    String label,
    MeasurementUnit value,
    ValueChanged<MeasurementUnit> onChanged,
    S strings,
  ) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MeasurementUnit>(
          value: value,
          isExpanded: true,
          onChanged: (unit) {
            if (unit != null) onChanged(unit);
          },
          items: [
            for (final unit in _quantity.units)
              DropdownMenuItem(
                value: unit,
                child: Text(
                  '${unit.label(strings)} (${unit.symbol})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final theme = Theme.of(context);
    final foreground = model.readableTextColor;
    final fieldBorder = OutlineInputBorder(
      borderSide: BorderSide(color: foreground),
    );
    final inputText = _amount.text.trim();
    final amount = Processor.parseNumericInput(inputText);
    final result = amount == null
        ? null
        : _from.convertTo(amount, _to, _quantity);
    final validResult = result != null && result.isFinite;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: foreground,
          onPrimary: model.backgroundColor,
          secondaryContainer: foreground,
          onSecondaryContainer: model.backgroundColor,
          surface: model.panelColor,
          onSurface: model.panelTextColor,
          onSurfaceVariant: foreground,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: fieldBorder,
          enabledBorder: fieldBorder,
          errorBorder: fieldBorder,
          errorStyle: TextStyle(color: foreground),
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          backgroundColor: model.backgroundColor,
          foregroundColor: foreground,
          title: Text(strings.unitConverter),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final quantity in MeasurementQuantity.values)
                        ChoiceChip(
                          label: Text(quantity.label(strings)),
                          selected: _quantity == quantity,
                          onSelected: (_) => _setQuantity(quantity),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    style: TextStyle(color: foreground),
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: strings.converterAmount,
                      errorText: inputText.isNotEmpty && amount == null
                          ? strings.formulaInvalidInput
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final from = _unitField(
                        strings.converterFrom,
                        _from,
                        (unit) => setState(() => _from = unit),
                        strings,
                      );
                      final to = _unitField(
                        strings.converterTo,
                        _to,
                        (unit) => setState(() => _to = unit),
                        strings,
                      );
                      final wide = constraints.maxWidth >= 460;
                      final swap = IconButton(
                        tooltip: strings.converterSwap,
                        color: foreground,
                        onPressed: () => _swap(result),
                        icon: Icon(wide ? Icons.swap_horiz : Icons.swap_vert),
                      );
                      if (wide) {
                        return Row(
                          children: [
                            Expanded(child: from),
                            swap,
                            Expanded(child: to),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          from,
                          Align(child: swap),
                          to,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: model.panelColor,
                      border: Border.all(color: model.panelBorderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                        liveRegion: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.scientificResult,
                              style: TextStyle(color: model.panelTextColor),
                            ),
                            SelectableText(
                              validResult
                                  ? '${Processor.formatResult(result)} ${_to.symbol}'
                                  : amount != null
                                  ? strings.error
                                  : strings.formulaNoResult,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: model.panelTextColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: validResult
                        ? () {
                            Processor.useResult(result);
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        : null,
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(strings.reuseResult),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
