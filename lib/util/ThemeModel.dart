import 'package:flutter/material.dart';
import 'package:simple_calculator/util/StorageManager.dart';

class ThemeModel with ChangeNotifier {
  static const kThemeColorIndex = 'kThemeColorIndex';

  /// 当前主题颜色
  int _themeColor = 0;
  int get themeColor => _themeColor;
  var backgroundColor;
  var buttonColor1;
  var buttonColor2;
  var buttonColor3;
  var textColor1;
  var textColor2;

  ThemeModel() {
    /// 获取主题色
    _themeColor = StorageManager.sharedPreferences.getInt(kThemeColorIndex) ?? 0;
    _changeTheme();
  }

  /// 切换指定色彩
  void switchTheme(int colorIndex) {
    _themeColor = colorIndex;
    _changeTheme();
    notifyListeners();
    StorageManager.sharedPreferences.setInt(kThemeColorIndex, colorIndex);
  }

  void _changeTheme() {
    if (_themeColor == 0) {
      backgroundColor = Color(0xffEFE4DC);
      buttonColor1 = Color(0xffA2917E);
      buttonColor2 = Color(0xffF39E5A);
      buttonColor3 = Color(0xff6E5940);
      textColor1 = Color(0xff766C64);
      textColor2 = Color(0xffFFFFFF);
    } else if (_themeColor == 1) {
      backgroundColor = Color(0xffEEEDF0);
      buttonColor1 = Color(0xffCCF6F3);
      buttonColor2 = Color(0xffFDB4CF);
      buttonColor3 = Color(0xffFAD715);
      textColor1 = Color(0xff63515D);
      textColor2 = Color(0xff445458);
    } else if (_themeColor == 2) {
      backgroundColor = Color(0xffEEEDF0);
      buttonColor1 = Color(0xffEEEDEF);
      buttonColor2 = Color(0xff3D837C);
      buttonColor3 = Color(0xff438DF2);
      textColor1 = Color(0xff303740);
      textColor2 = Color(0xff303740);
    } else if (_themeColor == 3) {
      backgroundColor = Color(0xff3B343F);
      buttonColor1 = Color(0xffF0ECE2);
      buttonColor2 = Color(0xff505469);
      buttonColor3 = Color(0xffC15851);
      textColor1 = Color(0xffFCFBFC);
      textColor2 = Color(0xff3B343F);
    } else if (_themeColor == 4) {
      backgroundColor = Color(0xffFFFFFF);
      buttonColor1 = Color(0xffEDD6E9);
      buttonColor2 = Color(0xffA8CDDD);
      buttonColor3 = Color(0xffBDACD6);
      textColor1 = Color(0xff241003);
      textColor2 = Color(0xff241003);
    } else if (_themeColor == 5) {
      backgroundColor = Color(0xffF6E9B6);
      buttonColor1 = Color(0xffF4B15E);
      buttonColor2 = Color(0xffF1C4C5);
      buttonColor3 = Color(0xffE59791);
      textColor1 = Color(0xff303740);
      textColor2 = Color(0xff303740);
    } else if (_themeColor == 6) {
      backgroundColor = Color(0xffFCFEEC);
      buttonColor1 = Color(0xffFDEDDE);
      buttonColor2 = Color(0xffADCFE1);
      buttonColor3 = Color(0xffCDA7A5);
      textColor1 = Color(0xff303740);
      textColor2 = Color(0xff303740);
    } else if (_themeColor == 7) {
      backgroundColor = Color(0xff277AC0);
      buttonColor1 = Color(0xffFECA45);
      buttonColor2 = Color(0xffFFF2CF);
      buttonColor3 = Color(0xffFD8400);
      textColor1 = Color(0xffFFF2CF);
      textColor2 = Color(0xff303740);
    } else if (_themeColor == 8) {
      backgroundColor = Color(0xff2E303E);
      buttonColor1 = Color(0xffEBE5CF);
      buttonColor2 = Color(0xffC1432F);
      buttonColor3 = Color(0xff61938A);
      textColor1 = Color(0xffF0ECE2);
      textColor2 = Color(0xff3B343F);
    } else if (_themeColor == 9) {
      backgroundColor = Color(0xffE69A8E);
      buttonColor1 = Color(0xffDCE3C1);
      buttonColor2 = Color(0xffECE0A8);
      buttonColor3 = Color(0xffFCD9C5);
      textColor1 = Color(0xffF0ECE2);
      textColor2 = Color(0xff3B343F);
    } else if (_themeColor == 10) {
      backgroundColor = Color(0xffFAFEE7);
      buttonColor1 = Color(0xffEC4761);
      buttonColor2 = Color(0xff2A3367);
      buttonColor3 = Color(0xffBAD6E8);
      textColor1 = Color(0xff3B343F);
      textColor2 = Color(0xffFAFEE7);
    } else if (_themeColor == 11) {
      backgroundColor = Color(0xff9F6697);
      buttonColor1 = Color(0xffF8D36E);
      buttonColor2 = Color(0xffF8826C);
      buttonColor3 = Color(0xff7EB5A1);
      textColor1 = Color(0xffFAFEE7);
      textColor2 = Color(0xff3B343F);
    } else if (_themeColor == 12) {
      backgroundColor = Color(0xffE1218A);
      buttonColor1 = Color(0xff68D1FB);
      buttonColor2 = Color(0xffF3E0E6);
      buttonColor3 = Color(0xffFC88C1);
      textColor1 = Color(0xffFAFEE7);
      textColor2 = Color(0xff3B343F);
    } else if (_themeColor == 13) {
      backgroundColor = Color(0xffF08347);
      buttonColor1 = Color(0xffFCCE91);
      buttonColor2 = Color(0xff68D1FB);
      buttonColor3 = Color(0xffF5F5DC);
      textColor1 = Color(0xffFAFEE7);
      textColor2 = Color(0xff3B343F);
    }else if (_themeColor == 14) {
      backgroundColor = Color(0xff81D975);
      buttonColor1 = Color(0xffD2FAB8);
      buttonColor2 = Color(0xffFFE7ED);
      buttonColor3 = Color(0xff5ED5DE);
      textColor1 = Color(0xff3B343F);
      textColor2 = Color(0xff3B343F);
    }else if (_themeColor == 15) {
      backgroundColor = Color(0xffA01C12);
      buttonColor1 = Color(0xffFEBB26);
      buttonColor2 = Color(0xffECC282);
      buttonColor3 = Color(0xff976A61);
      textColor1 = Color(0xffFAFEE7);
      textColor2 = Color(0xff3B343F);
    }else if (_themeColor == 16) {
      backgroundColor = Color(0xffEFCA32);
      buttonColor1 = Color(0xffA34C43);
      buttonColor2 = Color(0xffB37588);
      buttonColor3 = Color(0xff5ED5DE);
      textColor1 = Color(0xff47343F);
      textColor2 = Color(0xffFAFEE7);
    }else {
      backgroundColor = Color(0xffD0F3DE);
      buttonColor1 = Color(0xffA7EAD8);
      buttonColor2 = Color(0xff7DC3B9);
      buttonColor3 = Color(0xff709BAC);
      textColor1 = Color(0xff3B343F);
      textColor2 = Color(0xff3B343F);
    }
  }
}
