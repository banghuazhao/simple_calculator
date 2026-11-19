import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';

enum _Quantity {
  length,
  mass,
  volume,
  temperature;

  List<_Unit> get units => switch (this) {
    length => const [
      _Unit.meter,
      _Unit.foot,
      _Unit.centimeter,
      _Unit.inch,
      _Unit.kilometer,
      _Unit.mile,
    ],
    mass => const [
      _Unit.kilogram,
      _Unit.pound,
      _Unit.gram,
      _Unit.ounce,
      _Unit.milligram,
    ],
    volume => const [
      _Unit.liter,
      _Unit.usGallon,
      _Unit.milliliter,
      _Unit.usCup,
      _Unit.usFluidOunce,
    ],
    temperature => const [_Unit.celsius, _Unit.fahrenheit, _Unit.kelvin],
  };

  String label(S strings) => switch (this) {
    length => strings.converterLength,
    mass => strings.converterMass,
    volume => strings.converterVolume,
    temperature => strings.converterTemperature,
  };
}

enum _Unit {
  meter('m', 1),
  foot('ft', 0.3048),
  centimeter('cm', 0.01),
  inch('in', 0.0254),
  kilometer('km', 1000),
  mile('mi', 1609.344),
  kilogram('kg', 1),
  pound('lb', 0.45359237),
  gram('g', 0.001),
  ounce('oz', 0.028349523125),
  milligram('mg', 0.000001),
  liter('L', 1),
  usGallon('US gal', 3.785411784),
  milliliter('mL', 0.001),
  usCup('US cup', 0.2365882365),
  usFluidOunce('US fl oz', 0.0295735295625),
  celsius('°C'),
  fahrenheit('°F'),
  kelvin('K');

  const _Unit(this.symbol, [this.factor = 1]);

  final String symbol;
  final double factor;

  String label(S strings) => switch (this) {
    meter => strings.converterMeter,
    foot => strings.converterFoot,
    centimeter => strings.converterCentimeter,
    inch => strings.converterInch,
    kilometer => strings.converterKilometer,
    mile => strings.converterMile,
    kilogram => strings.converterKilogram,
    pound => strings.converterPound,
    gram => strings.converterGram,
    ounce => strings.converterOunce,
    milligram => strings.converterMilligram,
    liter => strings.converterLiter,
    usGallon => strings.converterUsGallon,
    milliliter => strings.converterMilliliter,
    usCup => strings.converterUsCup,
    usFluidOunce => strings.converterUsFluidOunce,
    celsius => strings.converterCelsius,
    fahrenheit => strings.converterFahrenheit,
    kelvin => strings.converterKelvin,
  };

  double convertTo(double amount, _Unit target, _Quantity quantity) {
    if (this == target) return amount;
    if (quantity != _Quantity.temperature) {
      return amount * (factor / target.factor);
    }

    final celsiusAmount = switch (this) {
      fahrenheit => (amount - 32) * (5 / 9),
      kelvin => amount - 273.15,
      _ => amount,
    };
    return switch (target) {
      fahrenheit => celsiusAmount * (9 / 5) + 32,
      kelvin => celsiusAmount + 273.15,
      _ => celsiusAmount,
    };
  }
}

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  final _amount = TextEditingController();
  _Quantity _quantity = _Quantity.length;
  _Unit _from = _Unit.meter;
  _Unit _to = _Unit.foot;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setQuantity(_Quantity quantity) {
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
    _Unit value,
    ValueChanged<_Unit> onChanged,
    S strings,
  ) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_Unit>(
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
                      for (final quantity in _Quantity.values)
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
                            Navigator.of(context).pop();
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
