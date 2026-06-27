import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:open_store/open_store.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/util/ThemeModel.dart';
import 'package:simple_calculator/util/ads_manager.dart';

import 'generated/l10n.dart';

const int maxFailedLoadAttempts = 3;

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdsManager.interstitialAdUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        }, onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            _createInterstitialAd();
          }
        }));
  }

  void _showInterstitialAd() {
    // Respect the frequency cap so rapid theme switching doesn't spam ads.
    if (!AdsManager.canShowInterstitial) return;
    if (_interstitialAd != null) {
      _interstitialAd?.fullScreenContentCallback =
          FullScreenContentCallback(onAdShowedFullScreenContent: (InterstitialAd ad) {
        AdState.isShowingFullScreenAd = true;
        AdsManager.markInterstitialShown();
      }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
        AdState.isShowingFullScreenAd = false;
        ad.dispose();
        _createInterstitialAd();
      }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        AdState.isShowingFullScreenAd = false;
        ad.dispose();
        _createInterstitialAd();
      });
      _interstitialAd?.show();
    } else {}
  }

  @override
  void initState() {
    super.initState();
    if (!Platform.isMacOS) {
      _createInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<MoreAppItem> _items = [];

    var Classic_Memory_Game = MoreAppItem(
        Image.asset("assets/app_icons/classic_memory_game.png"), S.of(context).Classic_Memory_Game,
        () {
      OpenStore.instance
          .open(appStoreId: "1617593078", androidAppBundleId: "com.appsbay.classic_memory_game");
    });

    var Image_Guru =
        MoreAppItem(Image.asset("assets/app_icons/image_guru.png"), S.of(context).Image_Guru, () {
      OpenStore.instance.open(appStoreId: "1625021625", androidAppBundleId: "");
    });

    var Yes_Habit =
        MoreAppItem(Image.asset("assets/app_icons/yes_habit.png"), S.of(context).Yes_Habit, () {
      OpenStore.instance.open(appStoreId: "1637643734", androidAppBundleId: "");
    });

    var TripMark = MoreAppItem(
        Image.asset("assets/app_icons/tripmark.png"), S.of(context).TripMark, () {
      OpenStore.instance
          .open(appStoreId: "6464474080", androidAppBundleId: "");
    });

    var Shows = MoreAppItem(Image.asset("assets/app_icons/shows.png"), S.of(context).Shows, () {
      OpenStore.instance.open(appStoreId: "1624910011", androidAppBundleId: "com.appsbay.shows");
    });

    var Relaxing_Up =
        MoreAppItem(Image.asset("assets/app_icons/relaxing_up.png"), S.of(context).Relaxing_Up, () {
      OpenStore.instance
          .open(appStoreId: "1618712178", androidAppBundleId: "com.appsbay.relaxing_up");
    });

    var Easy_Unit =
        MoreAppItem(Image.asset("assets/app_icons/easy_unit.png"), S.of(context).Easy_Unit, () {
      OpenStore.instance.open(appStoreId: "1643640909", androidAppBundleId: "");
    });

    var Falling_Block_Puzzle = MoreAppItem(
        Image.asset("assets/app_icons/falling_block_puzzle.png"), S.of(context).Falling_Block_Puzzle, () {
      OpenStore.instance.open(appStoreId: "1609440799", androidAppBundleId: "");
    });

    var Simple_English_Dictionary = MoreAppItem(
        Image.asset("assets/app_icons/simple_english_dictionary.png"),
        S.of(context).Simple_English_Dictionary, () {
      OpenStore.instance.open(
          appStoreId: "1611258200", androidAppBundleId: "com.appsbay.simple_english_dictionary");
    });

    var Classic_Reversi = MoreAppItem(
        Image.asset("assets/app_icons/classic_reversi.png"), S.of(context).Classic_Reversi, () {
      OpenStore.instance
          .open(appStoreId: "1616580829", androidAppBundleId: "com.appsbay.classic_reversi");
    });

    var Onlynote =
        MoreAppItem(Image.asset("assets/app_icons/onlynote.png"), S.of(context).Onlynote, () {
      OpenStore.instance.open(appStoreId: "1616516732", androidAppBundleId: "com.appsbay.onlynote");
    });

    var World_Weather_Live = MoreAppItem(
        Image.asset("assets/app_icons/world_weather_live.png"), S.of(context).World_Weather_Live,
        () {
      OpenStore.instance
          .open(appStoreId: "1612773646", androidAppBundleId: "com.appsbay.world_weather_live");
    });

    var We_Play_Piano = MoreAppItem(
        Image.asset("assets/app_icons/we_play_piano.png"), S.of(context).We_Play_Piano, () {
      OpenStore.instance
          .open(appStoreId: "1625018611", androidAppBundleId: "com.appsbay.we_play_piano");
    });

    var sudoku_lovers = MoreAppItem(
        Image.asset("assets/app_icons/sudoku_lovers.png"), S.of(context).Sudoku_Lovers, () {
      OpenStore.instance
          .open(appStoreId: "1620749798", androidAppBundleId: "com.appsbay.sudoku_lovers");
    });

    var Instant_Face = MoreAppItem(
        Image.asset("assets/app_icons/instant_face.png"), S.of(context).Instant_Face, () {
      OpenStore.instance
          .open(appStoreId: "1638563222", androidAppBundleId: "com.appsbay.instant_face");
    });

    var minesweeper_go = MoreAppItem(
        Image.asset("assets/app_icons/minesweeper_go.png"), S.of(context).Minesweeper_Go, () {
      OpenStore.instance
          .open(appStoreId: "1621899572", androidAppBundleId: "com.appsbay.classic_minesweeper");
    });

    if (Platform.isIOS) {
      _items = [
        TripMark,
        Falling_Block_Puzzle,
        Yes_Habit,
        Relaxing_Up,
        Easy_Unit,
        Classic_Memory_Game,
        sudoku_lovers,
        Image_Guru,
        We_Play_Piano,
        minesweeper_go,
        Shows,
        Simple_English_Dictionary,
        Onlynote,
        Instant_Face,
        World_Weather_Live,
        Classic_Reversi
      ];
    } else {
      _items = [
        sudoku_lovers,
        Relaxing_Up,
        Instant_Face,
        minesweeper_go,
        Classic_Memory_Game,
        We_Play_Piano,
        Shows,
        Simple_English_Dictionary,
        Onlynote,
        World_Weather_Live,
        Classic_Reversi
      ];
    }
    var model = Provider.of<ThemeModel>(context, listen: false);

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            S.of(context).More,
            style: TextStyle(color: model.textColor1),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: model.textColor1,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // elevation: 0,
          backgroundColor: model.backgroundColor,
        ),
        backgroundColor: model.backgroundColor,
        body: ListView(
          children: [
            Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  S.of(context).theme,
                  style: TextStyle(fontSize: 21, color: model.textColor1),
                )),
            Container(
              padding: EdgeInsets.fromLTRB(0, 24, 0, 0),
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...[
                    "assets/theme/theme1.png",
                    "assets/theme/theme2.png",
                    "assets/theme/theme3.png",
                    "assets/theme/theme4.png",
                    "assets/theme/theme5.png",
                    "assets/theme/theme6.png",
                    "assets/theme/theme7.png",
                    "assets/theme/theme8.png",
                    "assets/theme/theme9.png",
                    "assets/theme/theme10.png",
                    "assets/theme/theme11.png",
                    "assets/theme/theme12.png",
                    "assets/theme/theme13.png",
                    "assets/theme/theme14.png",
                    "assets/theme/theme15.png",
                    "assets/theme/theme16.png",
                    "assets/theme/theme17.png",
                    "assets/theme/theme18.png"
                  ].asMap().entries.map((entry) {
                    String themeImage = entry.value;
                    int index = entry.key;
                    return Container(
                      margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      decoration: BoxDecoration(
                        border: index == model.themeColor
                            ? Border.all(color: Color(0xff4ACE5F), width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage(themeImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // color: color,
                      child: InkWell(
                        onTap: () {
                          model.switchTheme(index);
                          setState(() {});
                          if (!Platform.isMacOS) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              _showInterstitialAd();
                            });
                          }
                        },
                        child: Container(
                          width: 90,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            if (!Platform.isMacOS)
              Container(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    S.of(context).MoreApps,
                    style: TextStyle(fontSize: 21, color: model.textColor1),
                  )),
            if (!Platform.isMacOS)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return MoreAppsRow.factory(_items[index]);
                },
              ),
            SizedBox(
              height: 50,
            )
          ],
        ));
  }
}

class MoreAppItem {
  Image appIcon;
  String title;
  void Function() onTap;

  MoreAppItem(this.appIcon, this.title, this.onTap);
}

class MoreAppsRow extends StatelessWidget {
  Image appIcon;
  IconData trailingIcon;
  String title;
  void Function() onTap;

  MoreAppsRow(
      {Key? key,
      this.trailingIcon = Icons.chevron_right_rounded,
      required this.appIcon,
      required this.title,
      required this.onTap})
      : super(key: key);

  MoreAppsRow.factory(MoreAppItem moreAppItem) 
      : appIcon = moreAppItem.appIcon,
        trailingIcon = Icons.chevron_right_rounded,
        title = moreAppItem.title,
        onTap = moreAppItem.onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onTap: onTap,
        child: ListTile(
          visualDensity: VisualDensity(vertical: 4), // to compact
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 50,
              width: 50,
              child: appIcon,
            ),
          ),
          trailing: Icon(trailingIcon),
          title: Text(
            title,
          ),
        ),
      ),
    );
  }
}

class MoreRow extends StatelessWidget {
  IconData leadingIcon;
  IconData trailingIcon;
  String title;
  void Function() onTap;

  MoreRow(
      {Key? key,
      this.trailingIcon = Icons.chevron_right_rounded,
      required this.leadingIcon,
      required this.title,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(leadingIcon),
        trailing: Icon(trailingIcon),
        title: Text(
          title,
        ),
      ),
    );
  }
}
