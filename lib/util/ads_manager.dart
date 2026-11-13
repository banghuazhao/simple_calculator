import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralised AdMob configuration and helpers.
///
/// ## Ad unit ID injection
///
/// IDs are resolved per build mode so production IDs never live in source:
///
///  * **Debug / profile builds** use Google's official sample ("test") unit IDs.
///    These are hardcoded below and are safe to commit — they never generate
///    real impressions and won't get the AdMob account flagged.
///  * **Release builds** use the real production unit IDs. They are *not* stored
///    in source. Instead they are injected at build time from a git-ignored
///    file via `--dart-define-from-file`:
///
///    ```
///    # debug (test ids, nothing to pass)
///    flutter run
///
///    # release / production (real ids injected from the git-ignored file)
///    flutter build apk    --dart-define-from-file=ad_ids.release.json
///    flutter build ipa    --dart-define-from-file=ad_ids.release.json
///    ```
///
///    See `ad_ids.release.example.json` for the expected keys, and
///    `scripts/build_release.sh` for a convenience wrapper.
class AdsManager {
  AdsManager._();

  static Future<bool>? _initialization;

  /// Ad services are optional and never gate the calculator's first frame.
  static Future<bool> initialize() => _initialization ??= _initialize();

  static Future<bool> _initialize() async {
    if (disableAllAdsForScreenshot ||
        (!Platform.isAndroid && !Platform.isIOS)) {
      return false;
    }
    try {
      await MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 15));
      return true;
    } catch (error) {
      debugPrint('Ads unavailable: $error');
      return false;
    }
  }

  static Future<void> disposeAd(Ad? ad) async {
    try {
      await ad?.dispose();
    } catch (error) {
      debugPrint('Ad cleanup unavailable: $error');
    }
  }

  /// Set to true before capturing App Store / Play Store screenshots so no
  /// ads are loaded or displayed.
  static bool disableAllAdsForScreenshot = false;

  // --- Google official sample/"test" unit IDs (safe to commit) -------------
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenAndroid =
      'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIOS =
      'ca-app-pub-3940256099942544/5575463023';

  // --- Production unit IDs, injected from the git-ignored release file ------
  // Empty by default so the app still compiles without the file; an empty ad
  // unit simply fails to load instead of showing a (test) ad in production.
  static const String _releaseBannerAndroid =
      String.fromEnvironment('BANNER_ANDROID');
  static const String _releaseBannerIOS = String.fromEnvironment('BANNER_IOS');
  static const String _releaseInterstitialAndroid =
      String.fromEnvironment('INTERSTITIAL_ANDROID');
  static const String _releaseInterstitialIOS =
      String.fromEnvironment('INTERSTITIAL_IOS');
  static const String _releaseAppOpenAndroid =
      String.fromEnvironment('APP_OPEN_ANDROID');
  static const String _releaseAppOpenIOS =
      String.fromEnvironment('APP_OPEN_IOS');

  static String _resolve({
    required String testAndroid,
    required String testIOS,
    required String releaseAndroid,
    required String releaseIOS,
  }) {
    if (disableAllAdsForScreenshot) return '';
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Ads are only supported on Android and iOS');
    }
    final bool android = Platform.isAndroid;
    if (kReleaseMode) {
      return android ? releaseAndroid : releaseIOS;
    }
    return android ? testAndroid : testIOS;
  }

  static String get bannerAdUnitId => _resolve(
        testAndroid: _testBannerAndroid,
        testIOS: _testBannerIOS,
        releaseAndroid: _releaseBannerAndroid,
        releaseIOS: _releaseBannerIOS,
      );

  static String get interstitialAdUnitId => _resolve(
        testAndroid: _testInterstitialAndroid,
        testIOS: _testInterstitialIOS,
        releaseAndroid: _releaseInterstitialAndroid,
        releaseIOS: _releaseInterstitialIOS,
      );

  static String get appOpenAdUnitId => _resolve(
        testAndroid: _testAppOpenAndroid,
        testIOS: _testAppOpenIOS,
        releaseAndroid: _releaseAppOpenAndroid,
        releaseIOS: _releaseAppOpenIOS,
      );

  // --- Interstitial frequency cap (user-friendly) --------------------------
  // Don't interrupt with a full-screen interstitial more than once per window,
  // no matter how often the trigger (e.g. theme switching) fires.
  static const Duration interstitialMinInterval = Duration(seconds: 45);
  static DateTime? _lastInterstitialTime;

  static bool get canShowInterstitial {
    if (disableAllAdsForScreenshot) return false;
    final last = _lastInterstitialTime;
    if (last == null) return true;
    return DateTime.now().difference(last) >= interstitialMinInterval;
  }

  static void markInterstitialShown() {
    _lastInterstitialTime = DateTime.now();
  }

  static void debugPrintID() {
    if (!kDebugMode) {
      // Loud warning if a production build forgot the injected release file.
      if (bannerAdUnitId.isEmpty) {
        debugPrint('⚠️  AdsManager: release ad unit IDs are EMPTY. '
            'Did you build with --dart-define-from-file=ad_ids.release.json?');
      }
      return;
    }
    debugPrint('AdsManager bannerAdUnitId: $bannerAdUnitId');
    debugPrint('AdsManager interstitialAdUnitId: $interstitialAdUnitId');
    debugPrint('AdsManager appOpenAdUnitId: $appOpenAdUnitId');
  }
}

/// Shared guard so two full-screen formats (interstitial / app open) never try
/// to show at the same time.
class AdState {
  AdState._();
  static bool isShowingFullScreenAd = false;
}

/// Loads and shows App Open ads on app foreground, with a cooldown so a user
/// flipping in and out of the app isn't bombarded.
class AppOpenAdManager {
  AppOpenAdManager({bool Function()? adsAllowed}) : _adsAllowed = adsAllowed;

  final bool Function()? _adsAllowed;
  AppOpenAd? _appOpenAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastShowTime;

  /// Maximum time a loaded ad stays fresh before we reload (Google guidance).
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Minimum gap between two app open ad displays — keeps it non-annoying.
  final Duration minShowInterval = const Duration(minutes: 1);

  bool get isAdAvailable => _appOpenAd != null;

  bool get _canLoadOrShow =>
      !AdsManager.disableAllAdsForScreenshot && (_adsAllowed?.call() ?? true);

  void discardCachedAd() {
    if (_isShowingAd) return;
    final ad = _appOpenAd;
    _appOpenAd = null;
    _appOpenLoadTime = null;
    unawaited(AdsManager.disposeAd(ad));
  }

  bool get _isExpired {
    final loaded = _appOpenLoadTime;
    return loaded == null ||
        DateTime.now().subtract(maxCacheDuration).isAfter(loaded);
  }

  Future<void> loadAd() async {
    if (!_canLoadOrShow || _isLoadingAd || isAdAvailable) return;
    _isLoadingAd = true;
    try {
      if (!await AdsManager.initialize() || !_canLoadOrShow) {
        _isLoadingAd = false;
        return;
      }
      await AppOpenAd.load(
        adUnitId: AdsManager.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _isLoadingAd = false;
            if (!_canLoadOrShow) {
              unawaited(AdsManager.disposeAd(ad));
              return;
            }
            _appOpenLoadTime = DateTime.now();
            _appOpenAd = ad;
          },
          onAdFailedToLoad: (error) {
            _isLoadingAd = false;
            debugPrint('AppOpenAd failed to load: $error');
          },
        ),
      );
    } catch (error) {
      _isLoadingAd = false;
      debugPrint('App open ad unavailable: $error');
    }
  }

  /// Shows the ad if one is ready, not on cooldown, and nothing else is on
  /// screen. Otherwise (re)loads one for next time.
  Future<void> showAdIfAvailable() async {
    if (!_canLoadOrShow) return;
    if (_isShowingAd || AdState.isShowingFullScreenAd) return;

    if (!isAdAvailable || _isExpired) {
      discardCachedAd();
      loadAd();
      return;
    }

    final last = _lastShowTime;
    if (last != null && DateTime.now().difference(last) < minShowInterval) {
      return; // still on cooldown; keep the cached ad for later
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        AdState.isShowingFullScreenAd = true;
        _lastShowTime = DateTime.now();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        AdState.isShowingFullScreenAd = false;
        unawaited(AdsManager.disposeAd(ad));
        _appOpenAd = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        AdState.isShowingFullScreenAd = false;
        unawaited(AdsManager.disposeAd(ad));
        _appOpenAd = null;
        loadAd();
      },
    );
    // Reserve the full-screen slot before the asynchronous platform call, so
    // another foreground event cannot try to show the same ad twice.
    _isShowingAd = true;
    AdState.isShowingFullScreenAd = true;
    final ad = _appOpenAd!;
    try {
      await ad.show();
    } catch (error) {
      _isShowingAd = false;
      AdState.isShowingFullScreenAd = false;
      if (identical(_appOpenAd, ad)) _appOpenAd = null;
      unawaited(AdsManager.disposeAd(ad));
      debugPrint('App open ad could not be shown: $error');
    }
  }
}

/// Listens for app foreground events and shows an App Open ad when the user
/// returns to the app.
class AppLifecycleReactor with WidgetsBindingObserver {
  AppLifecycleReactor({
    required this.appOpenAdManager,
    this.refreshEntitlement,
  });

  final AppOpenAdManager appOpenAdManager;
  final Future<void> Function()? refreshEntitlement;

  void listen() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_showOnResume());
    }
  }

  Future<void> _showOnResume() async {
    await refreshEntitlement?.call();
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      await appOpenAdManager.showAdIfAvailable();
    }
  }
}
