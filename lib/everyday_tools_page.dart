import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/everyday_calculations.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/unit_converter_page.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
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
        const SizedBox(height: 8),
        tool(
          strings.everydayDiscountTax,
          Icons.local_offer_outlined,
          const _DiscountTaxPage(),
        ),
        const SizedBox(height: 8),
        tool(
          strings.everydayPercentTools,
          Icons.trending_up,
          const _PercentToolsPage(),
        ),
        const SizedBox(height: 8),
        tool(
          strings.everydayDateCalculator,
          Icons.calendar_today_outlined,
          const _DateCalculatorPage(),
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
  static const _tipPresets = [10, 15, 18, 20, 25];

  final _bill = TextEditingController();
  final _tip = TextEditingController(text: '0');
  final _people = TextEditingController(text: '1');
  bool _roundUp = false;

  @override
  void dispose() {
    _bill.dispose();
    _tip.dispose();
    _people.dispose();
    super.dispose();
  }

  void _update(String _) => setState(() {});

  void _setControllerText(TextEditingController controller, String text) {
    setState(() {
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _stepPeople(int delta) {
    final current = EverydayNumber.parse(_people.text)?.wholeNumber ?? BigInt.one;
    final next = current + BigInt.from(delta);
    if (next < BigInt.one) return;
    _setControllerText(_people, next.toString());
  }

  void _useInCalculator(double value) {
    Processor.useResult(value);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final bill = EverydayNumber.parse(_bill.text)?.cents;
    final tip = EverydayNumber.parse(_tip.text);
    final people = EverydayNumber.parse(_people.text)?.wholeNumber;
    final canSplit =
        bill != null && tip != null && people != null && people > BigInt.zero;
    final split = canSplit
        ? BillSplit(bill: bill, tipPercent: tip, people: people)
        : null;
    final displayValue = Processor.currentNumericValue;
    final canPullDisplay =
        displayValue != null && displayValue > 0 && displayValue < 1e12;
    final selectedTip = _tip.text.trim();

    return _ToolPage(
      title: strings.everydayTipSplitter,
      children: [
        _NumberField(
          controller: _bill,
          label: strings.everydayBill,
          error: bill == null ? strings.everydayMoneyError : null,
          onChanged: _update,
        ),
        if (canPullDisplay) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionChip(
              avatar: Icon(
                Icons.calculate_outlined,
                size: 16,
                color: model.panelTextColor,
              ),
              label: Text(
                strings.useCurrentDisplay(
                  displayValue.toStringAsFixed(2),
                ),
              ),
              onPressed: () =>
                  _setControllerText(_bill, displayValue.toStringAsFixed(2)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _NumberField(
          controller: _tip,
          label: strings.everydayTipPercent,
          error: tip == null ? strings.everydayNonnegativeError : null,
          onChanged: _update,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final preset in _tipPresets)
              ChoiceChip(
                label: Text('$preset%'),
                selected: selectedTip == '$preset',
                onSelected: (_) => _setControllerText(_tip, '$preset'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: _people,
                label: strings.everydayPeople,
                error: people == null || people <= BigInt.zero
                    ? strings.everydayCountError
                    : null,
                onChanged: _update,
                decimal: false,
                last: true,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: strings.decreasePeople,
              color: model.readableTextColor,
              onPressed: (people != null && people > BigInt.one)
                  ? () => _stepPeople(-1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: strings.increasePeople,
              color: model.readableTextColor,
              onPressed: () => _stepPeople(1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ToolPanel(
          child: SwitchListTile.adaptive(
            key: const ValueKey('bill-round-up'),
            title: Text(strings.roundUpPerPerson),
            value: _roundUp,
            onChanged: (value) => setState(() => _roundUp = value),
          ),
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
                      amount: formatCents(
                        _roundUp ? split.roundedTip : split.tip,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayBillTotal,
                      amount: formatCents(
                        _roundUp ? split.roundedTotal : split.total,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_roundUp)
                      _ResultAmount(
                        label: strings.everydayPerPerson,
                        amount: formatCents(split.roundedPerPerson),
                      )
                    else if (split.extraPeople == BigInt.zero)
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
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            final tipAmt = formatCents(
                              _roundUp ? split.roundedTip : split.tip,
                            );
                            final totalAmt = formatCents(
                              _roundUp ? split.roundedTotal : split.total,
                            );
                            final perPersonLine = _roundUp
                                ? '${strings.everydayPerPerson}: ${formatCents(split.roundedPerPerson)}'
                                : split.extraPeople == BigInt.zero
                                ? '${strings.everydayPerPerson}: ${formatCents(split.baseShare)}'
                                : '${strings.everydayPerPerson}:\n'
                                      '${_group(strings, split.extraPeople, split.baseShare + BigInt.one)}\n'
                                      '${_group(strings, split.people - split.extraPeople, split.baseShare)}';
                            ClipboardHelper.copy(
                              context,
                              '${strings.everydayTipAmount}: $tipAmt\n'
                              '${strings.everydayBillTotal}: $totalAmt\n'
                              '$perPersonLine',
                            );
                          },
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(strings.copySummary),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            final targetCents = _roundUp
                                ? split.roundedPerPerson
                                : (split.people == BigInt.one
                                      ? split.total
                                      : split.baseShare);
                            _useInCalculator(targetCents.toDouble() / 100);
                          },
                          icon: const Icon(Icons.calculate_outlined),
                          label: Text(strings.reuseResult),
                        ),
                      ],
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
  _ProductInput({this.unit = MeasurementUnit.gram});

  final price = TextEditingController();
  final size = TextEditingController();
  final pack = TextEditingController(text: '1');
  MeasurementUnit? unit;

  void dispose() {
    price.dispose();
    size.dispose();
    pack.dispose();
  }
}

class _UnitPricePage extends StatefulWidget {
  const _UnitPricePage();

  @override
  State<_UnitPricePage> createState() => _UnitPricePageState();
}

class _UnitPricePageState extends State<_UnitPricePage> {
  static const _maxItems = 6;

  _PriceQuantity _quantity = _PriceQuantity.mass;
  final List<_ProductInput> _items = [_ProductInput(), _ProductInput()];

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _update(String _) => setState(() {});

  void _changeQuantity(_PriceQuantity quantity) {
    if (quantity == _quantity) return;
    setState(() {
      _quantity = quantity;
      for (final item in _items) {
        item.unit = quantity.defaultUnit;
      }
    });
  }

  void _addItem() {
    if (_items.length >= _maxItems) return;
    setState(() {
      _items.add(_ProductInput(unit: _quantity.defaultUnit));
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 2) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  String _itemLabel(S strings, int index) {
    if (index == 0) return strings.everydayItemA;
    if (index == 1) return strings.everydayItemB;
    final letter = String.fromCharCode(65 + index);
    return strings.everydayItemLabel(letter);
  }

  String _keyPrefix(int index) {
    final letter = String.fromCharCode(97 + index);
    return 'item-$letter';
  }

  BigInt? _validPack(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return BigInt.one;
    final n = EverydayNumber.parse(trimmed)?.wholeNumber;
    return n != null && n > BigInt.zero ? n : null;
  }

  UnitPrice? _unitPrice(_ProductInput product) {
    final price = EverydayNumber.parse(product.price.text)?.cents;
    final size = _validSize(product.size.text);
    final pack = _validPack(product.pack.text);
    if (price == null || size == null || pack == null) return null;
    final totalSize = pack == BigInt.one ? size : size.multiplyWhole(pack);
    final factor = product.unit?.factor ?? 1.0;
    return UnitPrice(
      price: price,
      size: totalSize,
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

  Widget _product(S strings, int index, _ProductInput product) {
    final label = _itemLabel(strings, index);
    final keyPrefix = _keyPrefix(index);
    final size = _validSize(product.size.text);
    final price = EverydayNumber.parse(product.price.text)?.cents;
    final pack = _validPack(product.pack.text);
    final unit = product.unit;
    return _ToolPanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (index >= 2)
                  IconButton(
                    tooltip: strings.everydayRemoveItem,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _removeItem(index),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _NumberField(
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NumberField(
                    key: ValueKey('$keyPrefix-pack'),
                    controller: product.pack,
                    label: strings.everydayPackCount,
                    error: pack == null ? strings.everydayCountError : null,
                    onChanged: _update,
                    decimal: false,
                    last: true,
                  ),
                ),
              ],
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
    final prices = [for (final item in _items) _unitPrice(item)];
    final allValid = prices.every((p) => p != null);
    final reference = _quantity.referenceUnit(strings);

    String? headline;
    String? savingsDetail;
    if (allValid) {
      final valid = prices.cast<UnitPrice>();
      if (valid.length == 2) {
        final cmp = valid[0].compareTo(valid[1]);
        if (cmp < 0) {
          headline = strings.everydayItemACheaper;
          final pct = valid[0].percentSavingsOver(valid[1]);
          final sav = valid[0].formattedSavingsOver(valid[1]);
          if (pct != null && sav != null) {
            savingsDetail = strings.everydaySavesPercent(
              Processor.formatResult(pct),
              sav,
              reference,
            );
          }
        } else if (cmp > 0) {
          headline = strings.everydayItemBCheaper;
          final pct = valid[1].percentSavingsOver(valid[0]);
          final sav = valid[1].formattedSavingsOver(valid[0]);
          if (pct != null && sav != null) {
            savingsDetail = strings.everydaySavesPercent(
              Processor.formatResult(pct),
              sav,
              reference,
            );
          }
        } else {
          headline = strings.everydayEqualPrice;
        }
      } else {
        var bestIdx = 0;
        var worstIdx = 0;
        for (var i = 1; i < valid.length; i++) {
          if (valid[i].compareTo(valid[bestIdx]) < 0) bestIdx = i;
          if (valid[i].compareTo(valid[worstIdx]) > 0) worstIdx = i;
        }
        if (valid[bestIdx].compareTo(valid[worstIdx]) == 0) {
          headline = strings.everydayEqualPrice;
        } else {
          headline = strings.everydayBestValue(_itemLabel(strings, bestIdx));
          final pct = valid[bestIdx].percentSavingsOver(valid[worstIdx]);
          final sav = valid[bestIdx].formattedSavingsOver(valid[worstIdx]);
          if (pct != null && sav != null) {
            savingsDetail = strings.everydaySavesPercent(
              Processor.formatResult(pct),
              sav,
              reference,
            );
          }
        }
      }
    }

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
            final cards = [
              for (var i = 0; i < _items.length; i++)
                _product(strings, i, _items[i]),
            ];
            if (constraints.maxWidth >= 540 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24) {
              final rows = <Widget>[];
              for (var i = 0; i < cards.length; i += 2) {
                if (i > 0) rows.add(const SizedBox(height: 12));
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[i]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: i + 1 < cards.length
                            ? cards[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }
              return Column(children: rows);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  cards[i],
                ],
              ],
            );
          },
        ),
        if (_items.length < _maxItems) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('unit-price-add-item'),
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: Text(strings.everydayAddItem),
            ),
          ),
        ],
        if (allValid && headline != null) ...[
          const SizedBox(height: 16),
          _ToolPanel(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      headline,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (savingsDetail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        savingsDetail,
                        key: const ValueKey('unit-price-savings'),
                      ),
                    ],
                    for (var i = 0; i < prices.length; i++) ...[
                      const SizedBox(height: 12),
                      _ResultAmount(
                        label: _itemLabel(strings, i),
                        amount: strings.everydayUnitCost(
                          prices[i]!.formatted,
                          reference,
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
}

class _DiscountTaxPage extends StatefulWidget {
  const _DiscountTaxPage();

  @override
  State<_DiscountTaxPage> createState() => _DiscountTaxPageState();
}

class _DiscountTaxPageState extends State<_DiscountTaxPage> {
  static const _discountPresets = [10, 20, 25, 30, 50];

  final _price = TextEditingController();
  final _discount = TextEditingController(text: '20');
  final _extraDiscount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');

  @override
  void dispose() {
    _price.dispose();
    _discount.dispose();
    _extraDiscount.dispose();
    _tax.dispose();
    super.dispose();
  }

  void _update(String _) => setState(() {});

  void _setField(TextEditingController c, String text) {
    setState(() {
      c.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  double? _parsePercent(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final val = Processor.parseNumericInput(trimmed);
    if (val == null || val < 0 || val > 100) return null;
    return val;
  }

  double? _parseNonNegative(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    final val = Processor.parseNumericInput(trimmed);
    if (val == null || val < 0) return null;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final priceVal = Processor.parseNumericInput(_price.text);
    final validPrice = priceVal != null && priceVal >= 0;
    final discVal = _parsePercent(_discount.text);
    final extraVal = _parsePercent(_extraDiscount.text);
    final taxVal = _parseNonNegative(_tax.text);
    final calc =
        validPrice && discVal != null && extraVal != null && taxVal != null
        ? DiscountCalculation(
            originalPrice: priceVal,
            discountPercent: discVal,
            extraDiscountPercent: extraVal,
            taxPercent: taxVal,
          )
        : null;
    final displayValue = Processor.currentNumericValue;

    return _ToolPage(
      title: strings.everydayDiscountTax,
      children: [
        _NumberField(
          controller: _price,
          label: strings.everydayOriginalPrice,
          error: !validPrice ? strings.everydayNonnegativeError : null,
          onChanged: _update,
        ),
        if (displayValue != null && displayValue > 0) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionChip(
              avatar: Icon(
                Icons.calculate_outlined,
                size: 16,
                color: model.panelTextColor,
              ),
              label: Text(
                strings.useCurrentDisplay(Processor.formatResult(displayValue)),
              ),
              onPressed: () =>
                  _setField(_price, Processor.formatResult(displayValue)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _NumberField(
          controller: _discount,
          label: strings.everydayDiscountPercent,
          error: discVal == null ? strings.everydayNonnegativeError : null,
          onChanged: _update,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final preset in _discountPresets)
              ChoiceChip(
                label: Text('$preset%'),
                selected: _discount.text.trim() == '$preset',
                onSelected: (_) => _setField(_discount, '$preset'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _extraDiscount,
          label: strings.everydayExtraDiscountPercent,
          error: extraVal == null ? strings.everydayNonnegativeError : null,
          onChanged: _update,
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _tax,
          label: strings.everydayTaxPercent,
          error: taxVal == null ? strings.everydayNonnegativeError : null,
          onChanged: _update,
          last: true,
        ),
        if (calc != null) ...[
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
                      label: strings.everydayYouSave,
                      amount: calc.totalSavings.toStringAsFixed(2),
                    ),
                    if (calc.taxAmount > 0) ...[
                      const SizedBox(height: 12),
                      _ResultAmount(
                        label: strings.everydayTaxAmount,
                        amount: calc.taxAmount.toStringAsFixed(2),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayFinalPrice,
                      amount: calc.finalPrice.toStringAsFixed(2),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => ClipboardHelper.copy(
                            context,
                            '${strings.everydayYouSave}: ${calc.totalSavings.toStringAsFixed(2)}\n'
                            '${strings.everydayFinalPrice}: ${calc.finalPrice.toStringAsFixed(2)}',
                          ),
                          icon: const Icon(Icons.copy_outlined),
                          label: Text(strings.copySummary),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Processor.useResult(
                              double.parse(calc.finalPrice.toStringAsFixed(2)),
                            );
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.calculate_outlined),
                          label: Text(strings.reuseResult),
                        ),
                      ],
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

class _PercentToolsPage extends StatefulWidget {
  const _PercentToolsPage();

  @override
  State<_PercentToolsPage> createState() => _PercentToolsPageState();
}

class _PercentToolsPageState extends State<_PercentToolsPage> {
  bool _marginMode = false;
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _update(String _) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final a = Processor.parseNumericInput(_first.text);
    final b = Processor.parseNumericInput(_second.text);
    final change = !_marginMode && a != null && b != null
        ? PercentChangeCalculation(from: a, to: b)
        : null;
    final margin = _marginMode && a != null && b != null
        ? MarginCalculation(cost: a, sellingPrice: b)
        : null;

    return _ToolPage(
      title: strings.everydayPercentTools,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(strings.everydayPercentChangeTab),
              selected: !_marginMode,
              onSelected: (_) => setState(() => _marginMode = false),
            ),
            ChoiceChip(
              label: Text(strings.everydayMarginTab),
              selected: _marginMode,
              onSelected: (_) => setState(() => _marginMode = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _first,
          label: _marginMode ? strings.everydayCost : strings.everydayFromValue,
          error: a == null ? strings.formulaInvalidInput : null,
          onChanged: _update,
          signed: true,
        ),
        const SizedBox(height: 12),
        _NumberField(
          controller: _second,
          label: _marginMode
              ? strings.everydaySellingPrice
              : strings.everydayToValue,
          error: b == null ? strings.formulaInvalidInput : null,
          onChanged: _update,
          signed: true,
          last: true,
        ),
        if (change != null) ...[
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
                      label: strings.everydayAbsoluteChange,
                      amount:
                          '${change.difference >= 0 ? '+' : ''}${Processor.formatResult(change.difference)}',
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayPercentChange,
                      amount: change.percentChange == null
                          ? strings.error
                          : '${change.percentChange! >= 0 ? '+' : ''}${Processor.formatResult(change.percentChange!)}%',
                    ),
                    if (change.percentChange != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilledButton.icon(
                          onPressed: () {
                            Processor.useResult(change.percentChange!);
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
        ],
        if (margin != null) ...[
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
                      label: strings.everydayProfit,
                      amount: Processor.formatResult(margin.profit),
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayMarkup,
                      amount: margin.markupPercent == null
                          ? strings.error
                          : '${Processor.formatResult(margin.markupPercent!)}%',
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayMargin,
                      amount: margin.marginPercent == null
                          ? strings.error
                          : '${Processor.formatResult(margin.marginPercent!)}%',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: () {
                          Processor.useResult(margin.profit);
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(strings.reuseResult),
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

class _DateCalculatorPage extends StatefulWidget {
  const _DateCalculatorPage();

  @override
  State<_DateCalculatorPage> createState() => _DateCalculatorPageState();
}

class _DateCalculatorPageState extends State<_DateCalculatorPage> {
  bool _addMode = false;
  DateTime _start = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  late DateTime _end = _start.add(const Duration(days: 30));
  final _offsetDays = TextEditingController(text: '30');

  @override
  void dispose() {
    _offsetDays.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final diff = DateDifference(start: _start, end: _end);
    final offsetVal = int.tryParse(_offsetDays.text.trim());
    final targetDate = offsetVal != null && offsetVal.abs() <= 100000
        ? DateTime(_start.year, _start.month, _start.day + offsetVal)
        : null;

    Widget dateTile(String label, DateTime value, VoidCallback onTap) =>
        _ToolPanel(
          child: ListTile(
            title: Text(label),
            subtitle: Text(_formatDate(context, value)),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: onTap,
          ),
        );

    return _ToolPage(
      title: strings.everydayDateCalculator,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(strings.everydayDateDifferenceTab),
              selected: !_addMode,
              onSelected: (_) => setState(() => _addMode = false),
            ),
            ChoiceChip(
              label: Text(strings.everydayDateAddTab),
              selected: _addMode,
              onSelected: (_) => setState(() => _addMode = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        dateTile(strings.everydayStartDate, _start, () => _pickDate(isStart: true)),
        const SizedBox(height: 12),
        if (!_addMode) ...[
          dateTile(strings.everydayEndDate, _end, () => _pickDate(isStart: false)),
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
                      label: strings.everydayTotalDays,
                      amount: '${diff.totalDays}',
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayWeeksAndDays,
                      amount: '${diff.weeks}w ${diff.remainingDays}d',
                    ),
                    const SizedBox(height: 12),
                    _ResultAmount(
                      label: strings.everydayBusinessDays,
                      amount: '${diff.businessDays}',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          _NumberField(
            controller: _offsetDays,
            label: strings.everydayDaysOffset,
            error: targetDate == null ? strings.formulaInvalidInput : null,
            onChanged: (_) => setState(() {}),
            decimal: false,
            signed: true,
            last: true,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final preset in [-30, -7, 7, 30, 90])
                ChoiceChip(
                  label: Text('${preset > 0 ? '+' : ''}$preset'),
                  selected: _offsetDays.text.trim() == '$preset',
                  onSelected: (_) => setState(() {
                    _offsetDays.text = '$preset';
                  }),
                ),
            ],
          ),
          if (targetDate != null) ...[
            const SizedBox(height: 16),
            _ToolPanel(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: _ResultAmount(
                    label: strings.everydayResultDate,
                    amount: _formatDate(context, targetDate),
                  ),
                ),
              ),
            ),
          ],
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
    this.signed = false,
    this.last = false,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final ValueChanged<String> onChanged;
  final bool decimal;
  final bool signed;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.watch<ThemeModel>().readableTextColor),
      keyboardType: TextInputType.numberWithOptions(
        decimal: decimal,
        signed: signed,
      ),
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
