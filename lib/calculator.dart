import 'dart:async';
import 'dart:io';
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
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/shake_listener.dart';
import 'package:simple_calculator/util/clipboard_helper.dart';
import 'package:simple_calculator/util/input_feedback.dart';
import 'package:simple_calculator/util/input_settings.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  CalcState _calcState = const CalcState(current: '0', history: '');

  BannerAd? _ad;
  bool _isAdLoaded = false;

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

    if (Platform.isAndroid || Platform.isIOS) {
      // Plugin and sensor failures must not prevent the first calculator frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadBanner());
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

  Future<void> _loadBanner() async {
    if (!await AdsManager.initialize() || !mounted) return;
    try {
      final ad = BannerAd(
        adUnitId: AdsManager.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() => _isAdLoaded = true);
            } else {
              unawaited(AdsManager.disposeAd(ad));
            }
          },
          onAdFailedToLoad: (ad, error) => unawaited(AdsManager.disposeAd(ad)),
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (error) {
      debugPrint('Banner unavailable: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_keySubscription?.cancel());
    unawaited(_processorSubscription?.cancel());
    unawaited(AdsManager.disposeAd(_ad));
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
    final screenHeight = MediaQuery.of(context).size.height;
    final strings = S.of(context);

    return CalculatorShortcuts(
      onKey: (symbol) => input.KeyController.fire(
        input.KeyEvent(CalculatorKey(symbol: symbol)),
      ),
      onUndo: Processor.undo,
      onPaste: () => ClipboardHelper.paste(context),
      child: Scaffold(
        backgroundColor: model.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
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
                            color: model.textColor1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: strings.undo,
                          onPressed: Processor.canUndo ? Processor.undo : null,
                          color: model.textColor1,
                          disabledColor: model.textColor1.withValues(
                            alpha: 0.35,
                          ),
                          icon: const Icon(Icons.undo),
                        ),
                        IconButton(
                          tooltip: strings.pasteNumber,
                          onPressed: () => ClipboardHelper.paste(context),
                          icon: Icon(
                            Icons.content_paste,
                            color: model.textColor1,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.history,
                          onPressed: _showHistory,
                          icon: Icon(Icons.history, color: model.textColor1),
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
                  if (!Platform.isMacOS)
                    SizedBox(
                      height: 50,
                      child: _isAdLoaded && _ad != null
                          ? AdWidget(ad: _ad!)
                          : const SizedBox.shrink(),
                    )
                  else
                    const SizedBox(height: 20),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
