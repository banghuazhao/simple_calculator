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
  CalcState _calcState = const CalcState(current: '0', history: '');

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
      if (mounted) setState(() => _calcState = state);
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
    final ad = _ad;
    _ad = null;
    unawaited(AdsManager.disposeAd(ad));
    unawaited(_shakeListener?.dispose());
    super.dispose();
  }

  void _showHistory() {
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

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final allowsAds = context.select<PremiumController?, bool>(
      (premium) => premium?.allowsAds ?? true,
    );
    final showPremiumTools = context.select<PremiumController?, bool>(
      (premium) => premium?.isPremium ?? false,
    );
    final screenHeight = MediaQuery.of(context).size.height;
    final strings = S.of(context);
    final toolbarColor = model.readableTextColor;

    return CalculatorShortcuts(
      onKey: (symbol) => input.KeyController.fire(
        input.KeyEvent(CalculatorKey(symbol: symbol)),
      ),
      onUndo: Processor.undo,
      onCopy: () => ClipboardHelper.copyNumber(context, _calcState.current),
      onPaste: () => ClipboardHelper.paste(context),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        body: SafeArea(
          child: Center(
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
                          tooltip: strings.undo,
                          onPressed: Processor.canUndo ? Processor.undo : null,
                          color: toolbarColor,
                          disabledColor: toolbarColor.withValues(alpha: 0.35),
                          icon: const Icon(Icons.undo),
                        ),
                        IconButton(
                          tooltip: strings.pasteNumber,
                          onPressed: () => ClipboardHelper.paste(context),
                          icon: Icon(
                            Icons.content_paste_outlined,
                            color: toolbarColor,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.history,
                          onPressed: _showHistory,
                          icon: Icon(Icons.history, color: toolbarColor),
                        ),
                      ],
                    ),
                  ),
                  // Display fills all available space above keypad
                  Expanded(
                    child: Display(
                      current: _calcState.current,
                      history: _calcState.history,
                      isResult: _calcState.isResult,
                    ),
                  ),
                  const KeyPad(),
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
          ),
        ),
      ),
    );
  }
}
