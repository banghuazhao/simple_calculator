import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:simple_calculator/display.dart';
import 'package:simple_calculator/key-controller.dart';
import 'package:simple_calculator/key-pad.dart';
import 'package:simple_calculator/more_page.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/ThemeModel.dart';
import 'package:simple_calculator/util/ads_manager.dart';

class Calculator extends StatefulWidget {
  const Calculator({Key? key}) : super(key: key);

  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  CalcState _calcState = const CalcState(current: '0', history: '');

  BannerAd? _ad;
  bool _isAdLoaded = false;

  // Shake detection
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _lastX = 0, _lastY = 9.8, _lastZ = 0;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    KeyController.listen((event) => Processor.process(event));
    Processor.listen((state) => setState(() => _calcState = state));
    Processor.refresh();

    if (!Platform.isMacOS) {
      _ad = BannerAd(
        adUnitId: AdsManager.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => setState(() => _isAdLoaded = true),
          onAdFailedToLoad: (ad, error) => ad.dispose(),
        ),
      )..load();

      _accelSub = accelerometerEventStream().listen(_onAccelerometer);
    }
  }

  @override
  void dispose() {
    KeyController.dispose();
    Processor.dispose();
    _ad?.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  void _onAccelerometer(AccelerometerEvent e) {
    final dx = e.x - _lastX;
    final dy = e.y - _lastY;
    final dz = e.z - _lastZ;
    _lastX = e.x;
    _lastY = e.y;
    _lastZ = e.z;

    // Squared magnitude of delta — threshold ~sqrt(350) ≈ 18 m/s²
    final delta = dx * dx + dy * dy + dz * dz;
    if (delta > 350) {
      final now = DateTime.now();
      if (_lastShake == null ||
          now.difference(_lastShake!) > const Duration(milliseconds: 900)) {
        _lastShake = now;
        Processor.undo();
        HapticFeedback.mediumImpact();
      }
    }
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
        final entries = Processor.historyLog;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (entries.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              Processor.clearHistory();
                              setSheetState(() {});
                            },
                            child: Text(
                              'Clear',
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
                              'No calculations yet',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, indent: 20, endIndent: 20,
                                    color: textColor.withValues(alpha: 0.08)),
                            itemBuilder: (_, i) {
                              final entry = entries[i];
                              return InkWell(
                                onTap: () {
                                  Processor.setFromHistory(entry.result);
                                  Navigator.pop(ctx);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        entry.equation,
                                        style: TextStyle(
                                          color:
                                              textColor.withValues(alpha: 0.5),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MorePage()),
                        ),
                        icon: Icon(Icons.settings_outlined,
                            color: model.textColor1),
                      ),
                      const Spacer(),
                      IconButton(
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
                KeyPad(),
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
