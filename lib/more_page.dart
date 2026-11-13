import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:open_store/open_store.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/help_page.dart';
import 'package:simple_calculator/premium/premium_controller.dart';
import 'package:simple_calculator/premium/premium_page.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/input_settings.dart';

import 'generated/l10n.dart';

const int maxFailedLoadAttempts = 3;

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  bool _interstitialLoading = false;
  bool _themeChanged = false;
  PremiumController? _premium;

  bool get _allowsAds =>
      (Platform.isIOS || Platform.isAndroid) && (_premium?.allowsAds ?? true);

  void _syncInterstitial() {
    if (_allowsAds) {
      unawaited(_createInterstitialAd());
      return;
    }
    final ad = _interstitialAd;
    _interstitialAd = null;
    unawaited(AdsManager.disposeAd(ad));
  }

  Future<void> _createInterstitialAd() async {
    if (!mounted ||
        !_allowsAds ||
        _interstitialLoading ||
        _interstitialAd != null ||
        _interstitialLoadAttempts > maxFailedLoadAttempts) {
      return;
    }
    _interstitialLoading = true;
    try {
      if (!await AdsManager.initialize() || !mounted || !_allowsAds) {
        _interstitialLoading = false;
        return;
      }
      await InterstitialAd.load(
        adUnitId: AdsManager.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialLoading = false;
            if (!mounted || !_allowsAds) {
              unawaited(AdsManager.disposeAd(ad));
              return;
            }
            _interstitialAd = ad;
            _interstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (_) {
            _interstitialLoading = false;
            _interstitialLoadAttempts++;
            unawaited(_createInterstitialAd());
          },
        ),
      );
    } catch (error) {
      _interstitialLoading = false;
      debugPrint('Interstitial unavailable: $error');
    }
  }

  /// Shown once when leaving Settings after a theme change, never while the
  /// user is still browsing themes.
  void _showInterstitialAd() {
    final ad = _interstitialAd;
    if (ad == null ||
        !_allowsAds ||
        (_premium?.isBusy ?? false) ||
        AdState.isShowingFullScreenAd ||
        !AdsManager.canShowInterstitial) {
      return;
    }
    // The ad now owns its own disposal; this page may already be gone.
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        AdState.isShowingFullScreenAd = true;
        AdsManager.markInterstitialShown();
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        AdState.isShowingFullScreenAd = false;
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        AdState.isShowingFullScreenAd = false;
        ad.dispose();
      },
    );
    ad.show();
  }

  @override
  void initState() {
    super.initState();
    _premium = context.read<PremiumController?>();
    _premium?.addListener(_syncInterstitial);
    _syncInterstitial();
  }

  @override
  void dispose() {
    _premium?.removeListener(_syncInterstitial);
    unawaited(AdsManager.disposeAd(_interstitialAd));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premiumSupported = context.select<PremiumController?, bool>(
      (premium) => premium?.isSupported ?? false,
    );
    final showMoreApps = !Platform.isMacOS &&
        context.select<PremiumController?, bool>(
          (premium) => premium?.allowsAds ?? true,
        );
    List<MoreAppItem> items = [];

    var classicMemoryGame = MoreAppItem(
      Image.asset("assets/app_icons/classic_memory_game.png"),
      S.of(context).Classic_Memory_Game,
      () {
        OpenStore.instance.open(
          appStoreId: "1617593078",
          androidAppBundleId: "com.appsbay.classic_memory_game",
        );
      },
    );

    var imageGuru = MoreAppItem(
      Image.asset("assets/app_icons/image_guru.png"),
      S.of(context).Image_Guru,
      () {
        OpenStore.instance.open(
          appStoreId: "1625021625",
          androidAppBundleId: "",
        );
      },
    );

    var yesHabit = MoreAppItem(
      Image.asset("assets/app_icons/yes_habit.png"),
      S.of(context).Yes_Habit,
      () {
        OpenStore.instance.open(
          appStoreId: "1637643734",
          androidAppBundleId: "",
        );
      },
    );

    var tripMark = MoreAppItem(
      Image.asset("assets/app_icons/tripmark.png"),
      S.of(context).TripMark,
      () {
        OpenStore.instance.open(
          appStoreId: "6464474080",
          androidAppBundleId: "",
        );
      },
    );

    var shows = MoreAppItem(
      Image.asset("assets/app_icons/shows.png"),
      S.of(context).Shows,
      () {
        OpenStore.instance.open(
          appStoreId: "1624910011",
          androidAppBundleId: "com.appsbay.shows",
        );
      },
    );

    var relaxingUp = MoreAppItem(
      Image.asset("assets/app_icons/relaxing_up.png"),
      S.of(context).Relaxing_Up,
      () {
        OpenStore.instance.open(
          appStoreId: "1618712178",
          androidAppBundleId: "com.appsbay.relaxing_up",
        );
      },
    );

    var easyUnit = MoreAppItem(
      Image.asset("assets/app_icons/easy_unit.png"),
      S.of(context).Easy_Unit,
      () {
        OpenStore.instance.open(
          appStoreId: "1643640909",
          androidAppBundleId: "",
        );
      },
    );

    var fallingBlockPuzzle = MoreAppItem(
      Image.asset("assets/app_icons/falling_block_puzzle.png"),
      S.of(context).Falling_Block_Puzzle,
      () {
        OpenStore.instance.open(
          appStoreId: "1609440799",
          androidAppBundleId: "",
        );
      },
    );

    var simpleEnglishDictionary = MoreAppItem(
      Image.asset("assets/app_icons/simple_english_dictionary.png"),
      S.of(context).Simple_English_Dictionary,
      () {
        OpenStore.instance.open(
          appStoreId: "1611258200",
          androidAppBundleId: "com.appsbay.simple_english_dictionary",
        );
      },
    );

    var classicReversi = MoreAppItem(
      Image.asset("assets/app_icons/classic_reversi.png"),
      S.of(context).Classic_Reversi,
      () {
        OpenStore.instance.open(
          appStoreId: "1616580829",
          androidAppBundleId: "com.appsbay.classic_reversi",
        );
      },
    );

    var onlynote = MoreAppItem(
      Image.asset("assets/app_icons/onlynote.png"),
      S.of(context).Onlynote,
      () {
        OpenStore.instance.open(
          appStoreId: "1616516732",
          androidAppBundleId: "com.appsbay.onlynote",
        );
      },
    );

    var worldWeatherLive = MoreAppItem(
      Image.asset("assets/app_icons/world_weather_live.png"),
      S.of(context).World_Weather_Live,
      () {
        OpenStore.instance.open(
          appStoreId: "1612773646",
          androidAppBundleId: "com.appsbay.world_weather_live",
        );
      },
    );

    var wePlayPiano = MoreAppItem(
      Image.asset("assets/app_icons/we_play_piano.png"),
      S.of(context).We_Play_Piano,
      () {
        OpenStore.instance.open(
          appStoreId: "1625018611",
          androidAppBundleId: "com.appsbay.we_play_piano",
        );
      },
    );

    var sudokuLovers = MoreAppItem(
      Image.asset("assets/app_icons/sudoku_lovers.png"),
      S.of(context).Sudoku_Lovers,
      () {
        OpenStore.instance.open(
          appStoreId: "1620749798",
          androidAppBundleId: "com.appsbay.sudoku_lovers",
        );
      },
    );

    var instantFace = MoreAppItem(
      Image.asset("assets/app_icons/instant_face.png"),
      S.of(context).Instant_Face,
      () {
        OpenStore.instance.open(
          appStoreId: "1638563222",
          androidAppBundleId: "com.appsbay.instant_face",
        );
      },
    );

    var minesweeperGo = MoreAppItem(
      Image.asset("assets/app_icons/minesweeper_go.png"),
      S.of(context).Minesweeper_Go,
      () {
        OpenStore.instance.open(
          appStoreId: "1621899572",
          androidAppBundleId: "com.appsbay.classic_minesweeper",
        );
      },
    );

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
        classicReversi,
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
        classicReversi,
      ];
    }
    final model = context.watch<ThemeModel>();
    final strings = S.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _themeChanged && !Platform.isMacOS) {
          _showInterstitialAd();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(strings.settings),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: model.backgroundColor,
          foregroundColor: model.readableTextColor,
        ),
        backgroundColor: model.backgroundColor,
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _SettingsGroup(
                    child: Column(
                      children: [
                        if (premiumSupported) ...[
                          ListTile(
                            leading: const Icon(
                              Icons.workspace_premium_outlined,
                            ),
                            title: Text(strings.premium),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PremiumPage(),
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: model.panelBorderColor,
                          ),
                        ],
                        ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(strings.helpAndShortcuts),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(builder: (_) => const HelpPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const InputSettingsSection(),
                  const SizedBox(height: 16),
                  _SettingsHeading(strings.theme),
                  _SettingsGroup(
                    child: Column(
                      children: [
                        const HighContrastSetting(),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 176,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 18,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) => _ThemePreview(
                              number: index + 1,
                              selected: index == model.themeColor,
                              onTap: () {
                                if (index == model.themeColor) return;
                                model.switchTheme(index);
                                _themeChanged = true;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  if (showMoreApps) ...[
                    const SizedBox(height: 24),
                    _SettingsHeading(strings.MoreApps),
                    for (final item in items) MoreAppsRow.factory(item),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: model.readableTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    return Material(
      color: model.panelColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: model.panelBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTileTheme(
        iconColor: model.panelTextColor,
        textColor: model.panelTextColor,
        child: child,
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ThemeModel>();
    final radius = BorderRadius.circular(12);
    final selectionColor = model.panelTextColor;

    return Semantics(
      label: '${S.of(context).theme} $number',
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          width: 82,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? selectionColor : model.panelBorderColor,
              width: selected ? 2 : 1,
            ),
            image: DecorationImage(
              image: AssetImage('assets/theme/theme$number.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: selected
                ? Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selectionColor,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: ThemeModel.readableOn(
                              selectionColor,
                              model.panelColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class HighContrastSetting extends StatelessWidget {
  const HighContrastSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final strings = S.of(context);
    return SwitchListTile.adaptive(
      key: const ValueKey('high-contrast-setting'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(strings.highContrast),
      subtitle: Text(strings.highContrastDescription),
      value: model.highContrastEnabled,
      onChanged: model.setHighContrastEnabled,
      activeThumbColor: model.highContrastEnabled ? Colors.black : null,
      activeTrackColor: model.highContrastEnabled ? Colors.white : null,
      inactiveThumbColor: model.highContrastEnabled ? Colors.white : null,
      inactiveTrackColor: model.highContrastEnabled
          ? const Color(0xff444444)
          : null,
    );
  }
}

class InputSettingsSection extends StatelessWidget {
  const InputSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ThemeModel>(context);
    final strings = S.of(context);
    final settings = InputSettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsHeading(strings.inputSettings),
          _SettingsGroup(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  key: const ValueKey('haptics-setting'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(strings.hapticFeedback),
                  subtitle: Text(strings.hapticFeedbackDescription),
                  value: settings.hapticsEnabled,
                  onChanged: settings.setHapticsEnabled,
                  activeThumbColor: model.highContrastEnabled
                      ? Colors.black
                      : null,
                  activeTrackColor: model.highContrastEnabled
                      ? Colors.white
                      : null,
                  inactiveThumbColor: model.highContrastEnabled
                      ? Colors.white
                      : null,
                  inactiveTrackColor: model.highContrastEnabled
                      ? const Color(0xff444444)
                      : null,
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: model.panelBorderColor,
                ),
                SwitchListTile.adaptive(
                  key: const ValueKey('shake-setting'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(strings.shakeToUndo),
                  subtitle: Text(strings.shakeToUndoDescription),
                  value: settings.shakeToUndoEnabled,
                  onChanged: settings.setShakeToUndoEnabled,
                  activeThumbColor: model.highContrastEnabled
                      ? Colors.black
                      : null,
                  activeTrackColor: model.highContrastEnabled
                      ? Colors.white
                      : null,
                  inactiveThumbColor: model.highContrastEnabled
                      ? Colors.white
                      : null,
                  inactiveTrackColor: model.highContrastEnabled
                      ? const Color(0xff444444)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  const MoreAppsRow({
    super.key,
    this.trailingIcon = Icons.chevron_right_rounded,
    required this.appIcon,
    required this.title,
    required this.onTap,
  });

  MoreAppsRow.factory(MoreAppItem moreAppItem, {super.key})
    : appIcon = moreAppItem.appIcon,
      trailingIcon = Icons.chevron_right_rounded,
      title = moreAppItem.title,
      onTap = moreAppItem.onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SettingsGroup(
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(height: 40, width: 40, child: appIcon),
          ),
          trailing: Icon(trailingIcon),
          title: Text(title),
          onTap: onTap,
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

  const MoreRow({
    super.key,
    this.trailingIcon = Icons.chevron_right_rounded,
    required this.leadingIcon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(leadingIcon),
        trailing: Icon(trailingIcon),
        title: Text(title),
      ),
    );
  }
}
