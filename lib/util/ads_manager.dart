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

  /// Set to true before capturing App Store / Play Store screenshots so no
  /// ads are loaded or displayed.
  static bool disableAllAdsForScreenshot = false;

  // --- Google official sample/"test" unit IDs (safe to commit) -------------
  // https://developers.google.com/admob/flutter/test-ads
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testAppOpenAndroid = 'ca-app-pub-3940256099942544/9257395921';
  static const String _testAppOpenIOS = 'ca-app-pub-3940256099942544/5575463023';

  // --- Production unit IDs, injected from the git-ignored release file ------
  // Empty by default so the app still compiles without the file; an empty ad
  // unit simply fails to load instead of showing a (test) ad in production.
  static const String _releaseBannerAndroid = String.fromEnvironment('BANNER_ANDROID');
  static const String _releaseBannerIOS = String.fromEnvironment('BANNER_IOS');
  static const String _releaseInterstitialAndroid = String.fromEnvironment('INTERSTITIAL_ANDROID');
  static const String _releaseInterstitialIOS = String.fromEnvironment('INTERSTITIAL_IOS');
  static const String _releaseAppOpenAndroid = String.fromEnvironment('APP_OPEN_ANDROID');
  static const String _releaseAppOpenIOS = String.fromEnvironment('APP_OPEN_IOS');

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
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastShowTime;

  /// Maximum time a loaded ad stays fresh before we reload (Google guidance).
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Minimum gap between two app open ad displays — keeps it non-annoying.
  final Duration minShowInterval = const Duration(minutes: 1);

  bool get isAdAvailable => _appOpenAd != null;

  bool get _isExpired {
    final loaded = _appOpenLoadTime;
    return loaded == null || DateTime.now().subtract(maxCacheDuration).isAfter(loaded);
  }

  void loadAd() {
    if (AdsManager.disableAllAdsForScreenshot) return;
    AppOpenAd.load(
      adUnitId: AdsManager.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the ad if one is ready, not on cooldown, and nothing else is on
  /// screen. Otherwise (re)loads one for next time.
  void showAdIfAvailable() {
    if (AdsManager.disableAllAdsForScreenshot) return;
    if (_isShowingAd || AdState.isShowingFullScreenAd) return;

    if (!isAdAvailable || _isExpired) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
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
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        AdState.isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}

/// Listens for app foreground events and shows an App Open ad when the user
/// returns to the app.
class AppLifecycleReactor with WidgetsBindingObserver {
  AppLifecycleReactor({required this.appOpenAdManager});

  final AppOpenAdManager appOpenAdManager;

  void listen() => WidgetsBinding.instance.addObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}
