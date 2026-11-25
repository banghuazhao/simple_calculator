import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/currency_converter.dart';
import 'package:simple_calculator/util/theme_model.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  State<CurrencyConverterPage> createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final _amount = TextEditingController(text: '100');
  final _customRate = TextEditingController();
  late String _from;
  late String _to;
  bool _refreshing = false;

  CurrencyConverterStore get _store => CurrencyConverterStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
    _from = _store.lastFrom;
    _to = _store.lastTo;
    _syncRateController();
  }

  @override
  void dispose() {
    _amount.dispose();
    _customRate.dispose();
    super.dispose();
  }

  void _syncRateController() {
    final rate = _store.rateBetween(_from, _to);
    final text = Processor.formatResult(double.parse(rate.toStringAsPrecision(6)));
    _customRate.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _setFrom(String code) {
    setState(() {
      _from = code;
      _store.setPair(_from, _to);
      _syncRateController();
    });
  }

  void _setTo(String code) {
    setState(() {
      _to = code;
      _store.setPair(_from, _to);
      _syncRateController();
    });
  }

  void _swap(double? result) {
    setState(() {
      final previous = _from;
      _from = _to;
      _to = previous;
      _store.setPair(_from, _to);
      if (result != null && result.isFinite) {
        final formatted = Processor.formatResult(result);
        _amount.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      _syncRateController();
    });
  }

  Future<void> _refreshRates() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final ok = await _store.refreshOnline();
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _syncRateController();
    });
    final strings = S.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? strings.currencyRefreshSuccess : strings.currencyRefreshFailed,
          ),
        ),
      );
  }

  Widget _currencyDropdown(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
          items: [
            for (final c in CurrencyConverterStore.currencies)
              DropdownMenuItem(
                value: c.code,
                child: Text(
                  '${c.code} (${c.symbol}) — ${c.name}',
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
    final displayValue = Processor.currentNumericValue;

    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final inputText = _amount.text.trim();
        final amount = Processor.parseNumericInput(inputText);
        final rate = _store.rateBetween(_from, _to);
        final isCustom = _store.hasCustomRate(_from, _to);
        final result = amount == null ? null : _store.convert(amount, _from, _to);
        final validResult = result != null && result.isFinite;
        final toInfo = CurrencyConverterStore.infoFor(_to);
        final rateText = Processor.formatResult(
          double.parse(rate.toStringAsPrecision(6)),
        );
        final statusText = isCustom
            ? strings.currencyCustomRateActive
            : _store.updatedAtIso != null
            ? strings.currencyUpdatedAt(_store.updatedAtIso!)
            : strings.currencyOfflineRates;

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
              title: Text(strings.currencyConverter),
              actions: [
                IconButton(
                  key: const ValueKey('currency-refresh-button'),
                  tooltip: strings.currencyRefreshRates,
                  onPressed: _refreshing ? null : _refreshRates,
                  icon: _refreshing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                      : const Icon(Icons.refresh),
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
                        TextField(
                          key: const ValueKey('currency-amount-field'),
                          controller: _amount,
                          style: TextStyle(color: foreground),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(32),
                          ],
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
                              onPressed: () {
                                final text = Processor.formatResult(
                                  displayValue,
                                );
                                setState(() {
                                  _amount.value = TextEditingValue(
                                    text: text,
                                    selection: TextSelection.collapsed(
                                      offset: text.length,
                                    ),
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fromField = _currencyDropdown(
                              strings.converterFrom,
                              _from,
                              _setFrom,
                            );
                            final toField = _currencyDropdown(
                              strings.converterTo,
                              _to,
                              _setTo,
                            );
                            final wide = constraints.maxWidth >= 460;
                            final swap = IconButton(
                              tooltip: strings.converterSwap,
                              color: foreground,
                              onPressed: () => _swap(result),
                              icon: Icon(
                                wide ? Icons.swap_horiz : Icons.swap_vert,
                              ),
                            );
                            if (wide) {
                              return Row(
                                children: [
                                  Expanded(child: fromField),
                                  swap,
                                  Expanded(child: toField),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                fromField,
                                Align(child: swap),
                                toField,
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
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              strings.scientificResult,
                                              style: TextStyle(
                                                color: model.panelTextColor,
                                              ),
                                            ),
                                            SelectableText(
                                              validResult
                                                  ? '${toInfo.symbol}${result.toStringAsFixed(2)} $_to'
                                                  : strings.formulaNoResult,
                                              key: const ValueKey(
                                                'currency-result-text',
                                              ),
                                              style: theme
                                                  .textTheme
                                                  .headlineSmall
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
                                            result.toStringAsFixed(2),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '1 $_from = $rateText $_to · $statusText',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: model.panelTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('currency-custom-rate'),
                                controller: _customRate,
                                style: TextStyle(color: foreground),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.done,
                                onChanged: (text) {
                                  final parsed = Processor.parseNumericInput(
                                    text,
                                  );
                                  if (parsed != null && parsed > 0) {
                                    _store.setCustomRate(_from, _to, parsed);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText:
                                      '${strings.currencyCustomRate} (1 $_from → $_to)',
                                ),
                              ),
                            ),
                            if (isCustom) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                key: const ValueKey('currency-reset-rate'),
                                tooltip: strings.currencyResetRate,
                                color: foreground,
                                icon: const Icon(Icons.restore),
                                onPressed: () {
                                  _store.clearCustomRate(_from, _to);
                                  _syncRateController();
                                },
                              ),
                            ],
                          ],
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
          ),
        );
      },
    );
  }
}
