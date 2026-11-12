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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageManager.init();
  SharedPreferencesHelper.localStorage = StorageManager.sharedPreferences;
  InputSettings.instance.load();
  Processor.restoreHistory();
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
      unawaited(_runOptionalService('desktop window',
          () => DesktopWindow.setWindowSize(const Size(350, 700))));
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

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key, this.premiumController});

  final PremiumController? premiumController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeModel>(
            create: (context) => ThemeModel(),
          ),
          if (premiumController case final controller?)
            ChangeNotifierProvider<PremiumController>.value(value: controller)
          else
            ChangeNotifierProvider<PremiumController>(create: (_) {
              final controller = PremiumController();
              unawaited(controller.initialize());
              return controller;
            }),
        ],
        child: Consumer<ThemeModel>(builder: (context, themeModel, child) {
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
              // print(locale);
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
            home: const Calculator(),
          );
        }));
  }
}
