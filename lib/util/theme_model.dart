import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class ThemeModel with ChangeNotifier {
  static const kThemeColorIndex = 'kThemeColorIndex';
  static const kHighContrastEnabled = 'kHighContrastEnabled';

  /// 当前主题颜色
  int _themeColor = 0;
  int get themeColor => _themeColor;
  bool _highContrastEnabled = false;
  bool get highContrastEnabled => _highContrastEnabled;
  (SharedPreferences, bool)? _pendingContrastWrite;
  Completer<void>? _contrastIdle;
  bool _writingContrast = false;
  late Color backgroundColor;
  late Color buttonColor1;
  late Color buttonColor2;
  late Color buttonColor3;
  late Color textColor1;
  late Color textColor2;

  Color get secondaryTextColor =>
      highContrastEnabled ? Colors.white : textColor1.withValues(alpha: 0.5);
  Color get mutedTextColor => highContrastEnabled
      ? const Color(0xffDDDDDD)
      : textColor1.withValues(alpha: 0.65);
  Color get dividerColor => highContrastEnabled
      ? const Color(0xff777777)
      : textColor1.withValues(alpha: 0.08);
  Color get handleColor => highContrastEnabled
      ? const Color(0xffAAAAAA)
      : textColor1.withValues(alpha: 0.2);

  ThemeData? get accessibilityTheme => highContrastEnabled
      ? ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.highContrastDark().copyWith(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
            outline: const Color(0xffAAAAAA),
          ),
          scaffoldBackgroundColor: Colors.black,
          dividerColor: dividerColor,
        )
      : null;

  ThemeModel() {
    /// 获取主题色
    Object? savedTheme;
    try {
      savedTheme = StorageManager.sharedPreferences?.get(kThemeColorIndex);
    } catch (error) {
      debugPrint('Saved theme unavailable; using default: $error');
    }
    _themeColor = savedTheme is int && savedTheme >= 0 && savedTheme <= 17
        ? savedTheme
        : 0;
    try {
      _highContrastEnabled =
          StorageManager.sharedPreferences?.get(kHighContrastEnabled) == true;
    } catch (error) {
      debugPrint(
        'Saved contrast preference unavailable; using default: $error',
      );
    }
    _changeTheme();
  }

  /// 切换指定色彩
  void switchTheme(int colorIndex) {
    if (colorIndex < 0 || colorIndex > 17) return;
    _themeColor = colorIndex;
    _changeTheme();
    notifyListeners();
    unawaited(StorageManager.saveInt(kThemeColorIndex, colorIndex));
  }

  void setHighContrastEnabled(bool enabled) {
    if (_highContrastEnabled == enabled) return;
    _highContrastEnabled = enabled;
    _changeTheme();
    notifyListeners();
    final preferences = StorageManager.sharedPreferences;
    if (preferences == null) return;
    _pendingContrastWrite = (preferences, enabled);
    _contrastIdle ??= Completer<void>();
    if (!_writingContrast) unawaited(_drainContrastWrites());
  }

  /// Exposed for deterministic persistence tests; application input never waits.
  @visibleForTesting
  Future<void> get pendingHighContrastWrites =>
      _contrastIdle?.future ?? Future<void>.value();

  Future<void> _drainContrastWrites() async {
    _writingContrast = true;
    while (_pendingContrastWrite != null) {
      final (preferences, enabled) = _pendingContrastWrite!;
      _pendingContrastWrite = null;
      try {
        final saved = await preferences.setBool(kHighContrastEnabled, enabled);
        if (!saved) debugPrint('Contrast preference could not be saved.');
      } catch (error) {
        debugPrint('Contrast preference could not be saved: $error');
      }
    }
    _writingContrast = false;
    final idle = _contrastIdle;
    _contrastIdle = null;
    idle?.complete();
  }

  void _changeTheme() {
    if (highContrastEnabled) {
      backgroundColor = Colors.black;
      buttonColor1 = const Color(0xff222222);
      buttonColor2 = const Color(0xff004A80);
      buttonColor3 = const Color(0xff3A3A3A);
      textColor1 = Colors.white;
      textColor2 = Colors.white;
      return;
    }
    if (_themeColor == 0) {
      backgroundColor = const Color(0xffEFE4DC);
      buttonColor1 = const Color(0xffA2917E);
      buttonColor2 = const Color(0xffF39E5A);
      buttonColor3 = const Color(0xff6E5940);
      textColor1 = const Color(0xff766C64);
      textColor2 = const Color(0xffFFFFFF);
    } else if (_themeColor == 1) {
      backgroundColor = const Color(0xffEEEDF0);
      buttonColor1 = const Color(0xffCCF6F3);
      buttonColor2 = const Color(0xffFDB4CF);
      buttonColor3 = const Color(0xffFAD715);
      textColor1 = const Color(0xff63515D);
      textColor2 = const Color(0xff445458);
    } else if (_themeColor == 2) {
      backgroundColor = const Color(0xffEEEDF0);
      buttonColor1 = const Color(0xffEEEDEF);
      buttonColor2 = const Color(0xff3D837C);
      buttonColor3 = const Color(0xff438DF2);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (_themeColor == 3) {
      backgroundColor = const Color(0xff3B343F);
      buttonColor1 = const Color(0xffF0ECE2);
      buttonColor2 = const Color(0xff505469);
      buttonColor3 = const Color(0xffC15851);
      textColor1 = const Color(0xffFCFBFC);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 4) {
      backgroundColor = const Color(0xffFFFFFF);
      buttonColor1 = const Color(0xffEDD6E9);
      buttonColor2 = const Color(0xffA8CDDD);
      buttonColor3 = const Color(0xffBDACD6);
      textColor1 = const Color(0xff241003);
      textColor2 = const Color(0xff241003);
    } else if (_themeColor == 5) {
      backgroundColor = const Color(0xffF6E9B6);
      buttonColor1 = const Color(0xffF4B15E);
      buttonColor2 = const Color(0xffF1C4C5);
      buttonColor3 = const Color(0xffE59791);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (_themeColor == 6) {
      backgroundColor = const Color(0xffFCFEEC);
      buttonColor1 = const Color(0xffFDEDDE);
      buttonColor2 = const Color(0xffADCFE1);
      buttonColor3 = const Color(0xffCDA7A5);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (_themeColor == 7) {
      backgroundColor = const Color(0xff277AC0);
      buttonColor1 = const Color(0xffFECA45);
      buttonColor2 = const Color(0xffFFF2CF);
      buttonColor3 = const Color(0xffFD8400);
      textColor1 = const Color(0xffFFF2CF);
      textColor2 = const Color(0xff303740);
    } else if (_themeColor == 8) {
      backgroundColor = const Color(0xff2E303E);
      buttonColor1 = const Color(0xffEBE5CF);
      buttonColor2 = const Color(0xffC1432F);
      buttonColor3 = const Color(0xff61938A);
      textColor1 = const Color(0xffF0ECE2);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 9) {
      backgroundColor = const Color(0xffE69A8E);
      buttonColor1 = const Color(0xffDCE3C1);
      buttonColor2 = const Color(0xffECE0A8);
      buttonColor3 = const Color(0xffFCD9C5);
      textColor1 = const Color(0xffF0ECE2);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 10) {
      backgroundColor = const Color(0xffFAFEE7);
      buttonColor1 = const Color(0xffEC4761);
      buttonColor2 = const Color(0xff2A3367);
      buttonColor3 = const Color(0xffBAD6E8);
      textColor1 = const Color(0xff3B343F);
      textColor2 = const Color(0xffFAFEE7);
    } else if (_themeColor == 11) {
      backgroundColor = const Color(0xff9F6697);
      buttonColor1 = const Color(0xffF8D36E);
      buttonColor2 = const Color(0xffF8826C);
      buttonColor3 = const Color(0xff7EB5A1);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 12) {
      backgroundColor = const Color(0xffE1218A);
      buttonColor1 = const Color(0xff68D1FB);
      buttonColor2 = const Color(0xffF3E0E6);
      buttonColor3 = const Color(0xffFC88C1);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 13) {
      backgroundColor = const Color(0xffF08347);
      buttonColor1 = const Color(0xffFCCE91);
      buttonColor2 = const Color(0xff68D1FB);
      buttonColor3 = const Color(0xffF5F5DC);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 14) {
      backgroundColor = const Color(0xff81D975);
      buttonColor1 = const Color(0xffD2FAB8);
      buttonColor2 = const Color(0xffFFE7ED);
      buttonColor3 = const Color(0xff5ED5DE);
      textColor1 = const Color(0xff3B343F);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 15) {
      backgroundColor = const Color(0xffA01C12);
      buttonColor1 = const Color(0xffFEBB26);
      buttonColor2 = const Color(0xffECC282);
      buttonColor3 = const Color(0xff976A61);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (_themeColor == 16) {
      backgroundColor = const Color(0xffEFCA32);
      buttonColor1 = const Color(0xffA34C43);
      buttonColor2 = const Color(0xffB37588);
      buttonColor3 = const Color(0xff5ED5DE);
      textColor1 = const Color(0xff47343F);
      textColor2 = const Color(0xffFAFEE7);
    } else {
      backgroundColor = const Color(0xffD0F3DE);
      buttonColor1 = const Color(0xffA7EAD8);
      buttonColor2 = const Color(0xff7DC3B9);
      buttonColor3 = const Color(0xff709BAC);
      textColor1 = const Color(0xff3B343F);
      textColor2 = const Color(0xff3B343F);
    }
  }
}
