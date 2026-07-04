import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/calculator.dart';
import 'package:simple_calculator/util/storage_manager.dart';
import 'package:simple_calculator/util/theme_model.dart';
import 'package:simple_calculator/util/ads_manager.dart';
import 'package:simple_calculator/util/in_app_reviewer_helper.dart';
import 'package:simple_calculator/util/local_storage.dart';

import 'generated/l10n.dart';

import 'package:desktop_window/desktop_window.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Platform.isMacOS) {
    Future.delayed(const Duration(seconds: 1), () {
      AppTrackingTransparency.requestTrackingAuthorization();
    });

    MobileAds.instance.initialize();

    AdsManager.debugPrintID();

    // App Open ad: preload now and show whenever the user returns to the app.
    final appOpenAdManager = AppOpenAdManager()..loadAd();
    AppLifecycleReactor(appOpenAdManager: appOpenAdManager).listen();
  } else {
    await DesktopWindow.setWindowSize(const Size(350, 700));
  }


  InAppReviewHelper.checkAndAskForReview();

  await SharedPreferencesHelper.init();

  await StorageManager.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(const CalculatorApp());
  });
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeModel>(
            create: (context) => ThemeModel(),
          ),
        ],
        child: Consumer<ThemeModel>(builder: (context, themeModel, child) {
          return MaterialApp(
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
                if (locale?.scriptCode == 'Hant') {
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
