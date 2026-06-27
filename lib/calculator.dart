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
  Calculator({Key? key}) : super(key: key);

  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _output = "";

  BannerAd? _ad;

  bool _isAdLoaded = false;

  @override
  void initState() {
    KeyController.listen((event) => Processor.process(event));
    Processor.listen((data) => setState(() {
          _output = data;
        }));
    Processor.refresh();

    if (!Platform.isMacOS) {
      _ad = BannerAd(
        adUnitId: AdsManager.bannerAdUnitId,
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Releases an ad resource when it fails to load
            ad.dispose();

            print('Ad load failed (code=${error.code} message=${error.message})');
          },
        ),
      );

      _ad?.load();
    }

    super.initState();
  }

  @override
  void dispose() {
    KeyController.dispose();
    Processor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<ThemeModel>(context, listen: false);
    print(MediaQuery.of(context).size.height);
    return Scaffold(
      backgroundColor: model.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MorePage()));
                  },
                  icon: Icon(
                    Icons.settings_outlined,
                    color: model.textColor1,
                  ),
                ),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
              SizedBox(
                height: 20,
              ),
              Display(value: _output),
              KeyPad(),
              SizedBox(
                height: MediaQuery.of(context).size.height <= 740 ? 10 : 30,
              ),
              _isAdLoaded && _ad != null
                  ? Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: AdWidget(ad: _ad!),
                      height: 50.0,
                    )
                  : Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                      height: Platform.isMacOS ? 20 : 50,
                    )
            ]),
          ],
        ),
      ),
    );
  }
}
