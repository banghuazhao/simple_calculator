import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/everyday_calculations.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/unit_converter_page.dart';
import 'package:simple_calculator/util/measurement_units.dart';
import 'package:simple_calculator/util/theme_model.dart';

class EverydayToolsPage extends StatelessWidget {
  const EverydayToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);

    Widget tool(String label, IconData icon, Widget destination) => _ToolPanel(
      child: ListTile(
        title: Text(label),
        leading: Icon(icon),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => destination)),
      ),
    );

    return _ToolPage(
      title: strings.everydayTools,
      children: [
        tool(
          strings.everydayTipSplitter,
          Icons.receipt_long_outlined,
          const _BillSplitterPage(),
        ),
        const SizedBox(height: 8),
        tool(
          strings.everydayUnitPrice,
          Icons.price_check,
          const _UnitPricePage(),
        ),
        const SizedBox(height: 8),
        tool(
          strings.unitConverter,
          Icons.swap_horiz,
          const UnitConverterPage(),
        ),
      ],
    );
  }
}

class _BillSplitterPage extends StatefulWidget {
  const _BillSplitterPage();

  @override
  State<_BillSplitterPage> createState() => _BillSplitterPageState();
}

class _BillSplitterPageState extends State<_BillSplitterPage> {
  final _bill = TextEditingController();
  final _tip = TextEditingController(text: '0');
  final _people = TextEditingController(text: '1');

  @override
  void dispose() {
    _bill.dispose();
    _tip.dispose();
    _people.dispose();
    super.dispose();
  }

  void _update(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final bill = EverydayNumber.parse(_bill.text)?.cents;
    final tip = EverydayNumber.parse(_tip.text);
    final people = EverydayNumber.parse(_people.text)?.wholeNumber;
    final canSplit =
        bill != null && tip != null && people != null && people > BigInt.zero;
    final split = canSplit
        ? BillSplit(bill: bill, tipPercent: tip, people: people)
        : null;

    return _ToolPage(
      title: strings.everydayTipSplitter,
      children: [
        _NumberField(
          controller: _bill,
          label: strings.everydayBill,
          error: bill == null ? strings.everydayMoneyError : null,
          onChanged: _update,
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _tip,
          label: strings.everydayTipPercent,
          error: tip == null ? strings.everydayNonnegativeError : null,
          onChanged: _update,
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _people,
          label: strings.everydayPeople,
          error: people == null || people <= BigInt.zero
              ? strings.everydayCountError
              : null,
          onChanged: _update,
          decimal: false,
          last: true,
        ),
        if (split != null) ...[
          const SizedBox(height: 16),
          _ToolPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResultAmount(
                      label: strings.everydayTipAmount,
                      amount: formatCents(split.tip),
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayBillTotal,
                      amount: formatCents(split.total),
                    ),
                    const SizedBox(height: 12),
                    if (split.extraPeople == BigInt.zero)
                      _ResultAmount(
                        label: strings.everydayPerPerson,
                        amount: formatCents(split.baseShare),
                      )
                    else ...[
                      Text(
                        strings.everydayPerPerson,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _group(
                          strings,
                          split.extraPeople,
                          split.baseShare + BigInt.one,
                        ),
                      ),
                      Text(
                        _group(
                          strings,
                          split.people - split.extraPeople,
                          split.baseShare,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _group(S strings, BigInt count, BigInt cents) {
    final amount = formatCents(cents);
    return count == BigInt.one
        ? strings.everydayOnePersonPays(amount)
        : strings.everydayPeoplePay(count.toString(), amount);
  }
}

enum _PriceQuantity {
  mass,
  volume,
  count;

  List<MeasurementUnit> get units => switch (this) {
    mass => MeasurementQuantity.mass.units,
    volume => MeasurementQuantity.volume.units,
    count => const [],
  };

  MeasurementUnit? get defaultUnit => switch (this) {
    mass => MeasurementUnit.gram,
    volume => MeasurementUnit.milliliter,
    count => null,
  };

  String label(S strings) => switch (this) {
    mass => strings.converterMass,
    volume => strings.converterVolume,
    count => strings.everydayCount,
  };

  String referenceUnit(S strings) => switch (this) {
    mass => MeasurementUnit.kilogram.symbol,
    volume => MeasurementUnit.liter.symbol,
    count => strings.everydayEach,
  };
}

class _ProductInput {
  final price = TextEditingController();
  final size = TextEditingController();
  MeasurementUnit? unit = MeasurementUnit.gram;

  void dispose() {
    price.dispose();
    size.dispose();
  }
}

class _UnitPricePage extends StatefulWidget {
  const _UnitPricePage();

  @override
  State<_UnitPricePage> createState() => _UnitPricePageState();
}

class _UnitPricePageState extends State<_UnitPricePage> {
  _PriceQuantity _quantity = _PriceQuantity.mass;
  final _first = _ProductInput();
  final _second = _ProductInput();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _update(String _) => setState(() {});

  void _changeQuantity(_PriceQuantity quantity) {
    if (quantity == _quantity) return;
    setState(() {
      _quantity = quantity;
      _first.unit = quantity.defaultUnit;
      _second.unit = quantity.defaultUnit;
    });
  }

  UnitPrice? _unitPrice(_ProductInput product) {
    final price = EverydayNumber.parse(product.price.text)?.cents;
    final size = _validSize(product.size.text);
    if (price == null || size == null) return null;
    final factor = product.unit?.factor ?? 1.0;
    return UnitPrice(
      price: price,
      size: size,
      baseUnits: EverydayNumber.parse(factor.toString())!,
    );
  }

  EverydayNumber? _validSize(String value) {
    final number = EverydayNumber.parse(value);
    if (number == null || !number.isPositive) return null;
    if (_quantity == _PriceQuantity.count && number.wholeNumber == null) {
      return null;
    }
    return number;
  }

  Widget _product(
    S strings,
    String label,
    String keyPrefix,
    _ProductInput product,
  ) {
    final size = _validSize(product.size.text);
    final price = EverydayNumber.parse(product.price.text)?.cents;
    final unit = product.unit;
    return _ToolPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            _NumberField(
              key: ValueKey('$keyPrefix-price'),
              controller: product.price,
              label: strings.everydayPrice,
              error: price == null ? strings.everydayMoneyError : null,
              onChanged: _update,
            ),
            const SizedBox(height: 12),
            _NumberField(
              key: ValueKey('$keyPrefix-size'),
              controller: product.size,
              label: strings.everydayPackageSize,
              error: size == null
                  ? (_quantity == _PriceQuantity.count
                        ? strings.everydayCountError
                        : strings.everydaySizeError)
                  : null,
              onChanged: _update,
              decimal: _quantity != _PriceQuantity.count,
              last: true,
            ),
            if (unit != null) ...[
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: strings.formulaInputUnit,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MeasurementUnit>(
                    key: ValueKey('$keyPrefix-unit'),
                    value: unit,
                    isExpanded: true,
                    onChanged: (selected) {
                      if (selected != null) {
                        setState(() => product.unit = selected);
                      }
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final firstPrice = _unitPrice(_first);
    final secondPrice = _unitPrice(_second);
    final reference = _quantity.referenceUnit(strings);
    return _ToolPage(
      title: strings.everydayUnitPrice,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final quantity in _PriceQuantity.values)
              ChoiceChip(
                label: Text(quantity.label(strings)),
                selected: quantity == _quantity,
                onSelected: (_) => _changeQuantity(quantity),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final first = _product(
              strings,
              strings.everydayItemA,
              'item-a',
              _first,
            );
            final second = _product(
              strings,
              strings.everydayItemB,
              'item-b',
              _second,
            );
            if (constraints.maxWidth >= 540 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  const SizedBox(width: 12),
                  Expanded(child: second),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [first, const SizedBox(height: 12), second],
            );
          },
        ),
        if (firstPrice != null && secondPrice != null) ...[
          const SizedBox(height: 16),
          _ToolPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(switch (firstPrice.compareTo(secondPrice)) {
                      < 0 => strings.everydayItemACheaper,
                      > 0 => strings.everydayItemBCheaper,
                      _ => strings.everydayEqualPrice,
                    }, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayItemA,
                      amount: strings.everydayUnitCost(
                        firstPrice.formatted,
                        reference,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayItemB,
                      amount: strings.everydayUnitCost(
                        secondPrice.formatted,
                        reference,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.error,
    required this.onChanged,
    this.decimal = true,
    this.last = false,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  final bool decimal;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.watch<ThemeModel>().readableTextColor),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(64)],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        errorText: controller.text.trim().isEmpty ? null : error,
      ),
    );
  }
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    final theme = Theme.of(context);
    final ink = model.readableTextColor;
    final outline = OutlineInputBorder(borderSide: BorderSide(color: ink));
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: model.panelTextColor,
          displayColor: model.panelTextColor,
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: ink,
          onPrimary: model.backgroundColor,
          secondaryContainer: model.panelTextColor,
          onSecondaryContainer: model.panelColor,
          surface: model.panelColor,
          onSurface: model.panelTextColor,
          onSurfaceVariant: model.panelTextColor,
          outline: ink,
          error: ink,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: outline,
          enabledBorder: outline,
          errorMaxLines: 3,
        ),
      ),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        appBar: AppBar(
          backgroundColor: model.backgroundColor,
          foregroundColor: ink,
          title: Text(title),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    return Material(
      color: model.panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: model.panelBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ResultAmount extends StatelessWidget {
  const _ResultAmount({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        SelectableText(
          amount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
