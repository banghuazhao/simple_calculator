import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/calculator.dart';
import 'package:simple_calculator/premium/premium_controller.dart';
import 'package:simple_calculator/processor.dart';
import 'package:simple_calculator/util/input_settings.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/in_app_reviewer_helper.dart';
import 'package:simple_calculator/util/local_storage.dart';

import 'generated/l10n.dart';

import 'package:desktop_window/desktop_window.dart';

const _kMacWindowWidthKey = 'macos_window_width';
const _kMacWindowHeightKey = 'macos_window_height';

Size _savedMacWindowSize() {
  try {
    final prefs = StorageManager.sharedPreferences;
    final width = prefs?.getDouble(_kMacWindowWidthKey);
    final height = prefs?.getDouble(_kMacWindowHeightKey);
    if (width != null &&
        height != null &&
        width.isFinite &&
        height.isFinite &&
        width >= 320 &&
        width <= 2400 &&
        height >= 540 &&
        height <= 1800) {
      return Size(width, height);
    }
  } catch (error) {
    debugPrint('Saved macOS window size unavailable: $error');
  }
  return const Size(350, 700);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageManager.init();
  SharedPreferencesHelper.localStorage = StorageManager.sharedPreferences;
  InputSettings.instance.load();
  Processor.restoreHistory();
  Processor.restoreDraft();
  Processor.restoreMemory();
  final premium = PremiumController();
  unawaited(premium.initialize());
  runApp(CalculatorApp(premiumController: premium));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Preserve the existing phone orientation preference without making a
    // platform orientation response a prerequisite for opening the app.
    unawaited(_runOptionalService('orientation', () {
      return SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
    }));
    if (Platform.isMacOS) {
      unawaited(_runOptionalService('desktop window', () async {
        await DesktopWindow.setMinWindowSize(const Size(320, 540));
        await DesktopWindow.setWindowSize(_savedMacWindowSize());
      }));
    }
    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(_runOptionalService(
          'review prompt', InAppReviewHelper.checkAndAskForReview));
      unawaited(_runOptionalService('ads', () => _initializeAds(premium)));
    }
  });
}

Future<void> _runOptionalService(
    String name, Future<void> Function() initialize) async {
  try {
    await initialize();
  } catch (error) {
    debugPrint('Optional $name unavailable: $error');
  }
}

Future<void> _initializeAds(PremiumController premium) async {
  await premium.initialize();
  if (Platform.isIOS && premium.allowsAds) {
    await _runOptionalService('tracking authorization', () async {
      await AppTrackingTransparency.requestTrackingAuthorization();
    });
  }
  final appOpenAdManager = AppOpenAdManager(
    adsAllowed: () => premium.allowsAds && !premium.isBusy,
  );
  premium.addListener(() {
    if (!premium.allowsAds) appOpenAdManager.discardCachedAd();
  });
  AppLifecycleReactor(
    appOpenAdManager: appOpenAdManager,
    refreshEntitlement: premium.refreshEntitlement,
  ).listen();
  if (premium.allowsAds && await AdsManager.initialize() && premium.allowsAds) {
    AdsManager.debugPrintID();
    await appOpenAdManager.loadAd();
  }
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key, this.premiumController});

  final PremiumController? premiumController;

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp>
    with WidgetsBindingObserver {
  Timer? _windowSaveTimer;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    _windowSaveTimer?.cancel();
    if (Platform.isMacOS) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!Platform.isMacOS) return;
    _windowSaveTimer?.cancel();
    _windowSaveTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final size = await DesktopWindow.getWindowSize();
        final prefs = StorageManager.sharedPreferences;
        if (prefs != null && size.width >= 320 && size.height >= 540) {
          await prefs.setDouble(_kMacWindowWidthKey, size.width);
          await prefs.setDouble(_kMacWindowHeightKey, size.height);
        }
      } catch (error) {
        debugPrint('Could not persist macOS window size: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(
          create: (context) => ThemeModel(),
        ),
        if (widget.premiumController case final controller?)
          ChangeNotifierProvider<PremiumController>.value(value: controller)
        else
          ChangeNotifierProvider<PremiumController>(create: (_) {
            final controller = PremiumController();
            unawaited(controller.initialize());
            return controller;
          }),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          final platformBrightness =
              WidgetsBinding.instance.platformDispatcher.platformBrightness;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            themeModel.updatePlatformBrightness(platformBrightness);
          });
          return MaterialApp(
            theme: themeModel.accessibilityTheme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            localeResolutionCallback: (locale, supportLocales) {
              // 中文 简繁体处理
              if (locale?.languageCode == 'zh') {
                final traditional = locale?.scriptCode == 'Hant' ||
                    ((locale?.scriptCode?.isEmpty ?? true) &&
                        const ['HK', 'TW', 'MO'].contains(locale?.countryCode));
                if (traditional) {
                  return const Locale('zh', 'HK'); //繁体
                } else {
                  return const Locale('zh', ''); //简体
                }
              }
              return const Locale('en', '');
            },
            builder: (context, appChild) {
              final resolved = themeModel.resolvedTheme(Theme.of(context));
              return Theme(
                data: resolved,
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: themeModel.systemOverlayStyle,
                  child: appChild ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const Calculator(),
          );
        },
      ),
    );
  }
}
