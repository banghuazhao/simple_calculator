import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
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
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    KeyController.dispose();
    Processor.dispose();
    _ad?.dispose();
    super.dispose();
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
                // Settings button row
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                    child: IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MorePage()),
                      ),
                      icon: Icon(Icons.settings_outlined, color: model.textColor1),
                    ),
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
