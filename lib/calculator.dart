import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_calculator/calculator_key.dart';
import 'package:simple_calculator/calculator_shortcuts.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/everyday_tools_page.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/history_sheet.dart';
import 'package:simple_calculator/key_controller.dart' as input;
import 'package:simple_calculator/key_pad.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/premium/premium_controller.dart';
import 'package:simple_calculator/premium/premium_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/shake_listener.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/input_settings.dart';

class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  static const double _sidebarBreakpoint = 960;

  final _calcState = ValueNotifier(Processor.state);
  bool _showHistorySidebar = true;

  BannerAd? _ad;
  bool _isAdLoaded = false;
  bool _bannerLoading = false;
  PremiumController? _premium;
  AppLifecycleListener? _premiumLifecycle;

  bool get _allowsAds => _premium?.allowsAds ?? true;

  // Shake detection
  ShakeListener? _shakeListener;
  StreamSubscription<input.KeyEvent>? _keySubscription;
  StreamSubscription<CalcState>? _processorSubscription;

  @override
  void initState() {
    super.initState();
    _keySubscription = input.KeyController.listen(Processor.process);
    _processorSubscription = Processor.listen((state) {
      if (mounted) _calcState.value = state;
    });
    Processor.refresh();

    final premium = context.read<PremiumController?>();
    if (defaultTargetPlatform == TargetPlatform.macOS && premium != null) {
      _premiumLifecycle = AppLifecycleListener(
        onResume: () => unawaited(premium.refreshEntitlement()),
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      _premium = premium;
      _premium?.addListener(_syncBanner);
      // Plugin and sensor failures must not prevent the first calculator frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncBanner();
      });
      try {
        _shakeListener = ShakeListener(
          isEnabled: () => InputSettings.instance.shakeToUndoEnabled,
          onShake: () {
            if (!mounted ||
                ModalRoute.of(context)?.isCurrent != true ||
                !Processor.canUndo) {
              return;
            }
            Processor.undo();
            unawaited(InputFeedback.mediumImpact());
          },
        )..listen(accelerometerEventStream());
      } catch (error) {
        debugPrint('Shake-to-undo unavailable: $error');
      }
    }
  }

  void _syncBanner() {
    if (!mounted) return;
    if (_allowsAds) {
      unawaited(_loadBanner());
      return;
    }
    final ad = _ad;
    if (ad == null) return;
    setState(() {
      _ad = null;
      _isAdLoaded = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AdsManager.disposeAd(ad));
    });
  }

  Future<void> _loadBanner() async {
    if (!_allowsAds || _bannerLoading || _ad != null) return;
    _bannerLoading = true;
    try {
      if (!await AdsManager.initialize() || !mounted || !_allowsAds) return;
      final ad = BannerAd(
        adUnitId: AdsManager.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted && _allowsAds && identical(_ad, ad)) {
              setState(() => _isAdLoaded = true);
            }
          },
          onAdFailedToLoad: (ad, _) {
            if (!identical(_ad, ad)) return;
            _ad = null;
            unawaited(AdsManager.disposeAd(ad));
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (error) {
      debugPrint('Banner unavailable: $error');
      final ad = _ad;
      _ad = null;
      unawaited(AdsManager.disposeAd(ad));
    } finally {
      _bannerLoading = false;
    }
  }

  @override
  void dispose() {
    _premiumLifecycle?.dispose();
    _premium?.removeListener(_syncBanner);
    unawaited(_keySubscription?.cancel());
    unawaited(_processorSubscription?.cancel());
    _calcState.dispose();
    final ad = _ad;
    _ad = null;
    unawaited(AdsManager.disposeAd(ad));
    unawaited(_shakeListener?.dispose());
    super.dispose();
  }

  void _handleHistoryAction() {
    final wide = MediaQuery.sizeOf(context).width >= _sidebarBreakpoint;
    if (wide) {
      setState(() => _showHistorySidebar = !_showHistorySidebar);
      return;
    }
    _showHistoryModal();
  }

  void _showHistoryModal() {
    final model = Provider.of<ThemeModel>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: model.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const HistorySheet(),
    );
  }

  void _openEverydayTools() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const EverydayToolsPage()),
    );
  }

  void _correctOperand(OperandEdit operand) {
    showDialog<void>(
      context: context,
      builder: (_) => _CorrectOperandDialog(
        operand: operand,
        percent:
            operand.position == OperandPosition.right &&
            _calcState.value.rightOperandIsPercent,
      ),
    );
  }

  Widget _memoryBar(
    BuildContext context,
    CalcState state,
    ThemeModel model,
    S strings,
  ) {
    final ink = model.panelTextColor;
    final hasMemory = state.memory != null;
    Widget button(String label, String tooltip, VoidCallback? onPressed) =>
        Expanded(
          child: Tooltip(
            message: tooltip,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ink,
                disabledForegroundColor: ink.withValues(alpha: 0.35),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: onPressed == null
                  ? null
                  : () {
                      unawaited(InputFeedback.keyClick());
                      onPressed();
                    },
              child: Text(label),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
      child: DecoratedBox(
        key: const ValueKey('calculator-memory-bar'),
        decoration: BoxDecoration(
          color: model.panelColor,
          border: Border.all(color: model.panelBorderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            button(
              'MC',
              strings.memoryClear,
              hasMemory ? Processor.memoryClear : null,
            ),
            button(
              'MR',
              strings.memoryRecall,
              hasMemory ? Processor.memoryRecall : null,
            ),
            button('M+', strings.memoryAdd, Processor.memoryAdd),
            button('M−', strings.memorySubtract, Processor.memorySubtract),
            if (hasMemory)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  'M: ${InputSettings.instance.formatDisplayNumber(state.memory!)}',
                  key: const ValueKey('calculator-memory-value'),
                  style: TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
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
    final model = Provider.of<ThemeModel>(context);
    final allowsAds = context.select<PremiumController?, bool>(
      (premium) => premium?.allowsAds ?? true,
    );
    final showPremiumTools = context.select<PremiumController?, bool>(
      (premium) => premium?.isPremium ?? false,
    );
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final showSidebar =
        screenSize.width >= _sidebarBreakpoint && _showHistorySidebar;
    final strings = S.of(context);
    final toolbarColor = model.readableTextColor;

    final calculatorColumn = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: strings.settings,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MorePage()),
                    ),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: toolbarColor,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'SwiftSum',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: toolbarColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (showPremiumTools)
                    IconButton(
                      tooltip: strings.premiumTools,
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const PremiumPage(),
                        ),
                      ),
                      icon: Icon(
                        Icons.workspace_premium_outlined,
                        color: toolbarColor,
                      ),
                    ),
                  IconButton(
                    tooltip: strings.everydayTools,
                    onPressed: _openEverydayTools,
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: toolbarColor,
                    ),
                  ),
                  ValueListenableBuilder<CalcState>(
                    valueListenable: _calcState,
                    builder: (_, state, _) => IconButton(
                      tooltip: strings.undo,
                      onPressed: state.canUndo ? Processor.undo : null,
                      color: toolbarColor,
                      disabledColor: toolbarColor.withValues(alpha: 0.35),
                      icon: const Icon(Icons.undo),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.history,
                    onPressed: _handleHistoryAction,
                    icon: Icon(Icons.history, color: toolbarColor),
                  ),
                ],
              ),
            ),
            // Display fills all available space above keypad
            Expanded(
              child: ValueListenableBuilder<CalcState>(
                valueListenable: _calcState,
                builder: (_, state, _) => Display(
                  current: state.current,
                  history: state.history,
                  isResult: state.isResult,
                  preview: state.preview,
                  leftOperand: state.leftOperand,
                  rightOperand: state.rightOperand,
                  binaryOperator: state.binaryOperator,
                  rightOperandIsPercent: state.rightOperandIsPercent,
                  onCorrectOperand: _correctOperand,
                  onBackspace: () => input.KeyController.fire(
                    input.KeyEvent(const CalculatorKey(symbol: Keys.back)),
                  ),
                  onPaste: () => ClipboardHelper.paste(context),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: InputSettings.instance,
              builder: (context, _) {
                if (!InputSettings.instance.memoryBarEnabled) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<CalcState>(
                  valueListenable: _calcState,
                  builder: (_, state, _) =>
                      _memoryBar(context, state, model, strings),
                );
              },
            ),
            ValueListenableBuilder<CalcState>(
              valueListenable: _calcState,
              builder: (_, state, _) => KeyPad(
                activeOperator: state.isResult ? null : state.binaryOperator,
              ),
            ),
            SizedBox(height: screenHeight <= 740 ? 8 : 24),
            // Banner ad
            if (!Platform.isMacOS && allowsAds)
              SizedBox(
                height: 50,
                child: _isAdLoaded && _ad != null
                    ? AdWidget(ad: _ad!)
                    : const SizedBox.shrink(),
              )
            else if (Platform.isMacOS)
              const SizedBox(height: 20),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return CalculatorShortcuts(
      onKey: (symbol) => input.KeyController.fire(
        input.KeyEvent(CalculatorKey(symbol: symbol)),
      ),
      onUndo: Processor.undo,
      onRedo: Processor.redo,
      onCopy: () =>
          ClipboardHelper.copyNumber(context, _calcState.value.current),
      onPaste: () => ClipboardHelper.paste(context),
      onHistory: _handleHistoryAction,
      onTools: _openEverydayTools,
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        body: SafeArea(
          child: showSidebar
              ? Row(
                  children: [
                    Expanded(child: calculatorColumn),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: model.panelBorderColor,
                    ),
                    const SizedBox(
                      width: 340,
                      child: HistorySheet(embedded: true),
                    ),
                  ],
                )
              : calculatorColumn,
        ),
      ),
    );
  }
}

class _CorrectOperandDialog extends StatefulWidget {
  const _CorrectOperandDialog({required this.operand, required this.percent});

  final OperandEdit operand;
  final bool percent;

  @override
  State<_CorrectOperandDialog> createState() => _CorrectOperandDialogState();
}

class _CorrectOperandDialogState extends State<_CorrectOperandDialog> {
  late final _input = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.operand.input,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: widget.operand.input.length,
      ),
    ),
  );
  OperandCorrection? _failure;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _save() {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final outcome = Processor.correctOperand(widget.operand, _input.text);
    if (outcome == OperandCorrection.applied) {
      Navigator.of(context).pop();
    } else {
      setState(() => _failure = outcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final model = context.watch<ThemeModel>();
    final ink = model.readableTextColor;
    final stale = _failure == OperandCorrection.stale;
    return AlertDialog(
      scrollable: true,
      backgroundColor: model.backgroundColor,
      title: Text(
        widget.operand.position == OperandPosition.left
            ? strings.editFirstOperand
            : strings.editSecondOperand,
        style: TextStyle(color: ink),
      ),
      content: TextField(
        controller: _input,
        autofocus: true,
        enabled: !stale,
        style: TextStyle(color: ink),
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_failure != null) setState(() => _failure = null);
        },
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: strings.converterAmount,
          labelStyle: TextStyle(color: ink),
          suffixText: widget.percent ? '%' : null,
          suffixStyle: TextStyle(color: ink),
          errorText: switch (_failure) {
            OperandCorrection.invalid => strings.formulaInvalidInput,
            OperandCorrection.stale => strings.operandChanged,
            _ => null,
          },
          errorStyle: TextStyle(color: ink),
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel, style: TextStyle(color: ink)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            foregroundColor: model.backgroundColor,
          ),
          onPressed: stale ? null : _save,
          child: Text(strings.formulaSave),
        ),
      ],
    );
  }
}
