import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/measurement_units.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';

class UnitPairPreset {
  const UnitPairPreset({
    required this.quantity,
    required this.from,
    required this.to,
  });

  final MeasurementQuantity quantity;
  final MeasurementUnit from;
  final MeasurementUnit to;

  String get label => '${from.symbol} → ${to.symbol}';

  Map<String, String> toJson() => {
    'q': quantity.name,
    'from': from.name,
    'to': to.name,
  };

  static UnitPairPreset? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final qName = raw['q'];
    final fromName = raw['from'];
    final toName = raw['to'];
    if (qName is! String || fromName is! String || toName is! String) {
      return null;
    }
    final quantity = MeasurementQuantity.values
        .where((q) => q.name == qName)
        .firstOrNull;
    if (quantity == null) return null;
    final units = quantity.units;
    final from = units.where((u) => u.name == fromName).firstOrNull;
    final to = units.where((u) => u.name == toName).firstOrNull;
    if (from == null || to == null || from == to) return null;
    return UnitPairPreset(quantity: quantity, from: from, to: to);
  }

  @override
  bool operator ==(Object other) =>
      other is UnitPairPreset &&
      other.quantity == quantity &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(quantity, from, to);
}

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  static const _quantityKey = 'converter_last_quantity';
  static const _fromKey = 'converter_last_from';
  static const _toKey = 'converter_last_to';
  static const categoryPairsKey = 'converter_category_pairs_v1';
  static const pinnedPairsKey = 'converter_pinned_pairs_v1';

  static const List<UnitPairPreset> defaultPinnedPairs = [
    UnitPairPreset(
      quantity: MeasurementQuantity.length,
      from: MeasurementUnit.kilometer,
      to: MeasurementUnit.mile,
    ),
    UnitPairPreset(
      quantity: MeasurementQuantity.temperature,
      from: MeasurementUnit.celsius,
      to: MeasurementUnit.fahrenheit,
    ),
    UnitPairPreset(
      quantity: MeasurementQuantity.mass,
      from: MeasurementUnit.kilogram,
      to: MeasurementUnit.pound,
    ),
  ];

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  static const _maxPinnedPairs = 12;

  final _amount = TextEditingController();
  MeasurementQuantity _quantity = MeasurementQuantity.length;
  MeasurementUnit _from = MeasurementUnit.meter;
  MeasurementUnit _to = MeasurementUnit.foot;
  final Map<MeasurementQuantity, (MeasurementUnit, MeasurementUnit)>
  _categoryPairs = {};
  List<UnitPairPreset> _pinnedPairs = List.of(
    UnitConverterPage.defaultPinnedPairs,
  );

  @override
  void initState() {
    super.initState();
    _restoreLastSelection();
  }

  void _restoreLastSelection() {
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs == null) return;

      final rawCategoryPairs = prefs.getString(
        UnitConverterPage.categoryPairsKey,
      );
      if (rawCategoryPairs != null) {
        final decoded = jsonDecode(rawCategoryPairs);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final q = MeasurementQuantity.values
                .where((item) => item.name == entry.key)
                .firstOrNull;
            if (q == null || entry.value is! List) continue;
            final list = entry.value as List;
            if (list.length != 2) continue;
            final from = q.units.where((u) => u.name == list[0]).firstOrNull;
            final to = q.units.where((u) => u.name == list[1]).firstOrNull;
            if (from != null && to != null) {
              _categoryPairs[q] = (from, to);
            }
          }
        }
      }

      final rawPinned = prefs.getString(UnitConverterPage.pinnedPairsKey);
      if (rawPinned != null) {
        final decoded = jsonDecode(rawPinned);
        if (decoded is List) {
          final parsed = <UnitPairPreset>[];
          for (final entry in decoded) {
            final preset = UnitPairPreset.fromJson(entry);
            if (preset != null && !parsed.contains(preset)) {
              parsed.add(preset);
            }
            if (parsed.length == _maxPinnedPairs) break;
          }
          _pinnedPairs = parsed;
        }
      }

      final qName = prefs.getString(UnitConverterPage._quantityKey);
      if (qName == null) return;
      final quantity = MeasurementQuantity.values
          .where((q) => q.name == qName)
          .firstOrNull;
      if (quantity == null) return;
      _quantity = quantity;
      final units = quantity.units;
      final fromName = prefs.getString(UnitConverterPage._fromKey);
      final toName = prefs.getString(UnitConverterPage._toKey);
      final savedPair = _categoryPairs[quantity];
      _from =
          units.where((u) => u.name == fromName).firstOrNull ??
          savedPair?.$1 ??
          units.first;
      _to =
          units.where((u) => u.name == toName).firstOrNull ??
          savedPair?.$2 ??
          units[1];
      _categoryPairs[_quantity] = (_from, _to);
    } catch (_) {
      // Fall back cleanly to defaults.
    }
  }

  void _persistSelection() {
    _categoryPairs[_quantity] = (_from, _to);
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs == null) return;
      unawaited(
        prefs.setString(UnitConverterPage._quantityKey, _quantity.name),
      );
      unawaited(prefs.setString(UnitConverterPage._fromKey, _from.name));
      unawaited(prefs.setString(UnitConverterPage._toKey, _to.name));
      final serializedPairs = {
        for (final entry in _categoryPairs.entries)
          entry.key.name: [entry.value.$1.name, entry.value.$2.name],
      };
      unawaited(
        prefs.setString(
          UnitConverterPage.categoryPairsKey,
          jsonEncode(serializedPairs),
        ),
      );
    } catch (_) {
      // Persistence is optional.
    }
  }

  void _persistPinnedPairs() {
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs == null) return;
      unawaited(
        prefs.setString(
          UnitConverterPage.pinnedPairsKey,
          jsonEncode(_pinnedPairs.map((p) => p.toJson()).toList()),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setQuantity(MeasurementQuantity quantity) {
    if (_quantity == quantity) return;
    setState(() {
      _quantity = quantity;
      final remembered = _categoryPairs[quantity];
      _from = remembered?.$1 ?? quantity.units.first;
      _to = remembered?.$2 ?? quantity.units[1];
    });
    _persistSelection();
  }

  void _applyPreset(UnitPairPreset preset) {
    setState(() {
      _quantity = preset.quantity;
      _from = preset.from;
      _to = preset.to;
    });
    _persistSelection();
  }

  bool get _isCurrentPinned => _pinnedPairs.contains(
    UnitPairPreset(quantity: _quantity, from: _from, to: _to),
  );

  void _togglePinCurrent() {
    if (_from == _to) return;
    final current = UnitPairPreset(quantity: _quantity, from: _from, to: _to);
    setState(() {
      if (_pinnedPairs.contains(current)) {
        _pinnedPairs.remove(current);
      } else {
        if (_pinnedPairs.length >= _maxPinnedPairs) {
          _pinnedPairs.removeLast();
        }
        _pinnedPairs.insert(0, current);
      }
    });
    _persistPinnedPairs();
  }

  void _swap(double? result) {
    setState(() {
      final previousFrom = _from;
      _from = _to;
      _to = previousFrom;
      if (result != null && result.isFinite) {
        final text = Processor.formatResult(result);
        _amount.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
    _persistSelection();
  }

  void _applyDisplayValue(double value) {
    final text = Processor.formatResult(value);
    setState(() {
      _amount.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
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
            if (unit != null) {
              onChanged(unit);
              _persistSelection();
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
    final displayValue = Processor.currentNumericValue;
    final otherUnits = amount == null
        ? const <MeasurementUnit>[]
        : _quantity.units.where((u) => u != _from && u != _to).toList();

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
          actions: [
            IconButton(
              key: const ValueKey('converter-pin-button'),
              tooltip: _isCurrentPinned
                  ? strings.converterUnpinPair
                  : strings.converterPinPair,
              onPressed: _from == _to ? null : _togglePinCurrent,
              icon: Icon(
                _isCurrentPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
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
                  if (displayValue != null && displayValue != 0) ...[
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
                            Processor.formatResult(displayValue),
                          ),
                        ),
                        onPressed: () => _applyDisplayValue(displayValue),
                      ),
                    ),
                  ],
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.scientificResult,
                                    style: TextStyle(
                                      color: model.panelTextColor,
                                    ),
                                  ),
                                  SelectableText(
                                    validResult
                                        ? '${Processor.formatResult(result)} ${_to.symbol}'
                                        : amount != null
                                        ? strings.error
                                        : strings.formulaNoResult,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: model.panelTextColor,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (validResult)
                              IconButton(
                                tooltip: strings.copyResult,
                                color: model.panelTextColor,
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () => ClipboardHelper.copy(
                                  context,
                                  Processor.formatResult(result),
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
                  if (_pinnedPairs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      strings.converterPinnedPairs,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      key: const ValueKey('converter-pinned-pairs'),
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final preset in _pinnedPairs)
                          ActionChip(
                            avatar: Icon(
                              Icons.push_pin_outlined,
                              size: 14,
                              color: model.panelTextColor,
                            ),
                            label: Text(preset.label),
                            onPressed: () => _applyPreset(preset),
                          ),
                      ],
                    ),
                  ],
                  if (validResult && otherUnits.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    DecoratedBox(
                      key: const ValueKey('converter-all-units'),
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
                            Semantics(
                              header: true,
                              child: Text(
                                strings.converterAllUnits,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: model.panelTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final unit in otherUnits) ...[
                              Builder(
                                builder: (context) {
                                  final converted = _from.convertTo(
                                    amount!,
                                    unit,
                                    _quantity,
                                  );
                                  if (!converted.isFinite) {
                                    return const SizedBox.shrink();
                                  }
                                  final formatted = Processor.formatResult(
                                    converted,
                                  );
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () =>
                                        ClipboardHelper.copy(context, formatted),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              unit.label(strings),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: model.panelTextColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              '$formatted ${unit.symbol}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                color: model.panelTextColor,
                                                fontWeight: FontWeight.w600,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
