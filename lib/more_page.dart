import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:open_store/open_store.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/util/theme_model.dart';
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
        request: const AdRequest(),
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
    }
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
    const interstitialDuration = Duration(milliseconds: 500);
    List<MoreAppItem> items = [];

    var classicMemoryGame = MoreAppItem(
        Image.asset("assets/app_icons/classic_memory_game.png"), S.of(context).Classic_Memory_Game,
        () {
      OpenStore.instance
          .open(appStoreId: "1617593078", androidAppBundleId: "com.appsbay.classic_memory_game");
    });

    var imageGuru =
        MoreAppItem(Image.asset("assets/app_icons/image_guru.png"), S.of(context).Image_Guru, () {
      OpenStore.instance.open(appStoreId: "1625021625", androidAppBundleId: "");
    });

    var yesHabit =
        MoreAppItem(Image.asset("assets/app_icons/yes_habit.png"), S.of(context).Yes_Habit, () {
      OpenStore.instance.open(appStoreId: "1637643734", androidAppBundleId: "");
    });

    var tripMark = MoreAppItem(
        Image.asset("assets/app_icons/tripmark.png"), S.of(context).TripMark, () {
      OpenStore.instance
          .open(appStoreId: "6464474080", androidAppBundleId: "");
    });

    var shows = MoreAppItem(Image.asset("assets/app_icons/shows.png"), S.of(context).Shows, () {
      OpenStore.instance.open(appStoreId: "1624910011", androidAppBundleId: "com.appsbay.shows");
    });

    var relaxingUp =
        MoreAppItem(Image.asset("assets/app_icons/relaxing_up.png"), S.of(context).Relaxing_Up, () {
      OpenStore.instance
          .open(appStoreId: "1618712178", androidAppBundleId: "com.appsbay.relaxing_up");
    });

    var easyUnit =
        MoreAppItem(Image.asset("assets/app_icons/easy_unit.png"), S.of(context).Easy_Unit, () {
      OpenStore.instance.open(appStoreId: "1643640909", androidAppBundleId: "");
    });

    var fallingBlockPuzzle = MoreAppItem(
        Image.asset("assets/app_icons/falling_block_puzzle.png"), S.of(context).Falling_Block_Puzzle, () {
      OpenStore.instance.open(appStoreId: "1609440799", androidAppBundleId: "");
    });

    var simpleEnglishDictionary = MoreAppItem(
        Image.asset("assets/app_icons/simple_english_dictionary.png"),
        S.of(context).Simple_English_Dictionary, () {
      OpenStore.instance.open(
          appStoreId: "1611258200", androidAppBundleId: "com.appsbay.simple_english_dictionary");
    });

    var classicReversi = MoreAppItem(
        Image.asset("assets/app_icons/classic_reversi.png"), S.of(context).Classic_Reversi, () {
      OpenStore.instance
          .open(appStoreId: "1616580829", androidAppBundleId: "com.appsbay.classic_reversi");
    });

    var onlynote =
        MoreAppItem(Image.asset("assets/app_icons/onlynote.png"), S.of(context).Onlynote, () {
      OpenStore.instance.open(appStoreId: "1616516732", androidAppBundleId: "com.appsbay.onlynote");
    });

    var worldWeatherLive = MoreAppItem(
        Image.asset("assets/app_icons/world_weather_live.png"), S.of(context).World_Weather_Live,
        () {
      OpenStore.instance
          .open(appStoreId: "1612773646", androidAppBundleId: "com.appsbay.world_weather_live");
    });

    var wePlayPiano = MoreAppItem(
        Image.asset("assets/app_icons/we_play_piano.png"), S.of(context).We_Play_Piano, () {
      OpenStore.instance
          .open(appStoreId: "1625018611", androidAppBundleId: "com.appsbay.we_play_piano");
    });

    var sudokuLovers = MoreAppItem(
        Image.asset("assets/app_icons/sudoku_lovers.png"), S.of(context).Sudoku_Lovers, () {
      OpenStore.instance
          .open(appStoreId: "1620749798", androidAppBundleId: "com.appsbay.sudoku_lovers");
    });

    var instantFace = MoreAppItem(
        Image.asset("assets/app_icons/instant_face.png"), S.of(context).Instant_Face, () {
      OpenStore.instance
          .open(appStoreId: "1638563222", androidAppBundleId: "com.appsbay.instant_face");
    });

    var minesweeperGo = MoreAppItem(
        Image.asset("assets/app_icons/minesweeper_go.png"), S.of(context).Minesweeper_Go, () {
      OpenStore.instance
          .open(appStoreId: "1621899572", androidAppBundleId: "com.appsbay.classic_minesweeper");
    });

    if (Platform.isIOS) {
      items = [
        tripMark,
        fallingBlockPuzzle,
        yesHabit,
        relaxingUp,
        easyUnit,
        classicMemoryGame,
        sudokuLovers,
        imageGuru,
        wePlayPiano,
        minesweeperGo,
        shows,
        simpleEnglishDictionary,
        onlynote,
        instantFace,
        worldWeatherLive,
        classicReversi
      ];
    } else {
      items = [
        sudokuLovers,
        relaxingUp,
        instantFace,
        minesweeperGo,
        classicMemoryGame,
        wePlayPiano,
        shows,
        simpleEnglishDictionary,
        onlynote,
        worldWeatherLive,
        classicReversi
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  S.of(context).theme,
                  style: TextStyle(fontSize: 21, color: model.textColor1),
                )),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...const [
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
                            ? Border.all(color: const Color(0xff4ACE5F), width: 2)
                            : null,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                            Future.delayed(interstitialDuration, () {
                              _showInterstitialAd();
                            });
                          }
                        },
                        child: const SizedBox(
                          width: 90,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (!Platform.isMacOS)
              Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    S.of(context).MoreApps,
                    style: TextStyle(fontSize: 21, color: model.textColor1),
                  )),
            if (!Platform.isMacOS)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return MoreAppsRow.factory(items[index]);
                },
              ),
            const SizedBox(
              height: 50,
            )
          ],
        ));
  }
}

class MoreAppItem {
  final Image appIcon;
  final String title;
  final void Function() onTap;

  const MoreAppItem(this.appIcon, this.title, this.onTap);
}

class MoreAppsRow extends StatelessWidget {
  final Image appIcon;
  final IconData trailingIcon;
  final String title;
  final void Function() onTap;

  const MoreAppsRow(
      {Key? key,
      this.trailingIcon = Icons.chevron_right_rounded,
      required this.appIcon,
      required this.title,
      required this.onTap})
      : super(key: key);

  MoreAppsRow.factory(MoreAppItem moreAppItem, {Key? key}) 
      : appIcon = moreAppItem.appIcon,
        trailingIcon = Icons.chevron_right_rounded,
        title = moreAppItem.title,
        onTap = moreAppItem.onTap,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white60,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        onTap: onTap,
        child: ListTile(
          visualDensity: const VisualDensity(vertical: 4), // to compact
          leading: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(
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
  final IconData leadingIcon;
  final IconData trailingIcon;
  final String title;
  final void Function() onTap;

  const MoreRow(
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
