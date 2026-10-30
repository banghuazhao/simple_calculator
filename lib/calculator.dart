import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/key_controller.dart';
import 'package:simple_calculator/key_pad.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/shake_listener.dart';

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

  @override
  void initState() {
    super.initState();
    KeyController.listen((event) => Processor.process(event));
    Processor.listen((state) => setState(() => _calcState = state));
    Processor.refresh();

    if (Platform.isAndroid || Platform.isIOS) {
      // Plugin and sensor failures must not prevent the first calculator frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadBanner());
      });
      try {
        _shakeListener = ShakeListener(
          onShake: () {
            Processor.undo();
            HapticFeedback.mediumImpact();
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
    KeyController.dispose();
    Processor.dispose();
    unawaited(AdsManager.disposeAd(_ad));
    unawaited(_shakeListener?.dispose());
    super.dispose();
  }

  void _showHistory() {
    final model = Provider.of<ThemeModel>(context, listen: false);
    final textColor = model.textColor1;
    final bgColor = model.backgroundColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final entries = Processor.historyLog;
            final strings = S.of(ctx);
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.history,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (entries.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: ctx,
                                builder: (dialogCtx) => AlertDialog(
                                  scrollable: true,
                                  title: Text(strings.clearHistoryTitle),
                                  content: Text(strings.clearHistoryMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogCtx, false),
                                      child: Text(strings.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogCtx, true),
                                      child: Text(strings.clear),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && ctx.mounted) {
                                Processor.clearHistory();
                                HapticFeedback.mediumImpact();
                                setSheetState(() {});
                              }
                            },
                            child: Text(
                              strings.clear,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 15,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // List
                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Text(
                              strings.noCalculationsYet,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: textColor.withValues(alpha: 0.08),
                            ),
                            itemBuilder: (_, i) {
                              final entry = entries[i];
                              return Dismissible(
                                key: ValueKey(entry.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  color: Colors.red,
                                  child: Icon(
                                    Icons.delete_outline,
                                    semanticLabel: strings.deleteCalculation,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) {
                                  Processor.removeHistoryEntry(entry.id);
                                  HapticFeedback.lightImpact();
                                  setSheetState(() {});
                                },
                                child: Semantics(
                                  button: true,
                                  hint: strings.reuseResult,
                                  child: InkWell(
                                    onTap: () {
                                      Processor.setFromHistory(entry.result);
                                      Navigator.pop(ctx);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            entry.equation,
                                            style: TextStyle(
                                              color: textColor.withValues(
                                                alpha: 0.5,
                                              ),
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            entry.result,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w300,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;
    final strings = S.of(context);

    return Scaffold(
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
                        disabledColor: model.textColor1.withValues(alpha: 0.35),
                        icon: const Icon(Icons.undo),
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
    );
  }
}
