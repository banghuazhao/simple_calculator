import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class CustomThemePalette {
  const CustomThemePalette({
    required this.background,
    required this.button1,
    required this.button2,
    required this.button3,
  });

  final Color background;
  final Color button1;
  final Color button2;
  final Color button3;

  static const fallback = CustomThemePalette(
    background: Color(0xff1E2430),
    button1: Color(0xff323B4D),
    button2: Color(0xff3B82F6),
    button3: Color(0xff4B5563),
  );

  Map<String, int> toJson() => {
    'background': background.toARGB32(),
    'button1': button1.toARGB32(),
    'button2': button2.toARGB32(),
    'button3': button3.toARGB32(),
  };

  static CustomThemePalette? fromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final bg = decoded['background'];
    final b1 = decoded['button1'];
    final b2 = decoded['button2'];
    final b3 = decoded['button3'];
    if (bg is! int || b1 is! int || b2 is! int || b3 is! int) return null;
    return CustomThemePalette(
      background: Color(bg | 0xFF000000),
      button1: Color(b1 | 0xFF000000),
      button2: Color(b2 | 0xFF000000),
      button3: Color(b3 | 0xFF000000),
    );
  }
}

class ThemeModel with ChangeNotifier {
  static const kThemeColorIndex = 'kThemeColorIndex';
  static const kHighContrastEnabled = 'kHighContrastEnabled';
  static const kFollowSystemTheme = 'kFollowSystemTheme';
  static const kLightThemeIndex = 'kLightThemeIndex';
  static const kDarkThemeIndex = 'kDarkThemeIndex';
  static const kUseCustomTheme = 'kUseCustomTheme';
  static const kCustomThemePalette = 'kCustomThemePalette';

  static const int themeCount = 18;

  static const List<String> themeNames = [
    'Warm Sand',
    'Cotton Candy',
    'Ocean Slate',
    'Midnight Plum',
    'Lavender Mist',
    'Honey Peach',
    'Cream Sky',
    'Cobalt Gold',
    'Charcoal Ember',
    'Terracotta Sage',
    'Crimson Navy',
    'Mulberry Sun',
    'Neon Berry',
    'Sunset Cyan',
    'Mint Meadow',
    'Ruby Gold',
    'Saffron Berry',
    'Seafoam',
  ];

  static const List<int> darkThemeIndices = [3, 7, 8, 11, 12, 15];
  static const List<int> lightThemeIndices = [
    0,
    1,
    2,
    4,
    5,
    6,
    9,
    10,
    13,
    14,
    16,
    17,
  ];

  static String themeName(int index) =>
      index >= 0 && index < themeNames.length
          ? themeNames[index]
          : 'Theme ${index + 1}';

  /// 当前主题颜色
  int _themeColor = 0;
  int get themeColor => _themeColor;
  bool _highContrastEnabled = false;
  bool get highContrastEnabled => _highContrastEnabled;

  bool _followSystemTheme = false;
  bool get followSystemTheme => _followSystemTheme;
  int _lightThemeIndex = 0;
  int get lightThemeIndex => _lightThemeIndex;
  int _darkThemeIndex = 8;
  int get darkThemeIndex => _darkThemeIndex;
  Brightness _platformBrightness = Brightness.light;

  bool _useCustomTheme = false;
  bool get useCustomTheme => _useCustomTheme;
  CustomThemePalette _customPalette = CustomThemePalette.fallback;
  CustomThemePalette get customPalette => _customPalette;

  int get activeThemeIndex {
    if (_followSystemTheme && !_useCustomTheme) {
      return _platformBrightness == Brightness.dark
          ? _darkThemeIndex
          : _lightThemeIndex;
    }
    return _themeColor;
  }

  (SharedPreferences, bool)? _pendingContrastWrite;
  Completer<void>? _contrastIdle;
  bool _writingContrast = false;
  late Color backgroundColor;
  late Color buttonColor1;
  late Color buttonColor2;
  late Color buttonColor3;
  late Color textColor1;
  late Color textColor2;

  Color get readableTextColor => readableOn(backgroundColor, textColor1);

  Color get panelColor {
    if (highContrastEnabled) return backgroundColor;
    final tint = backgroundColor.computeLuminance() < 0.2
        ? Colors.white
        : Colors.black;
    return Color.alphaBlend(tint.withValues(alpha: 0.045), backgroundColor);
  }

  Color get panelTextColor => readableOn(panelColor, textColor1);

  Color get panelBorderColor => highContrastEnabled
      ? dividerColor
      : panelTextColor.withValues(alpha: 0.18);

  Brightness get backgroundBrightness =>
      ThemeData.estimateBrightnessForColor(backgroundColor);

  SystemUiOverlayStyle get systemOverlayStyle =>
      backgroundBrightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark;

  static Color readableOn(Color background, Color preferred) {
    final surface = background.computeLuminance() + 0.05;
    final ink = preferred.computeLuminance() + 0.05;
    if (math.max(surface, ink) / math.min(surface, ink) >= 4.5) {
      return preferred;
    }
    return surface / 0.05 >= 1.05 / surface ? Colors.black : Colors.white;
  }

  static double contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance() + 0.05;
    final l2 = b.computeLuminance() + 0.05;
    return math.max(l1, l2) / math.min(l1, l2);
  }

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

  /// Kept null when high contrast is off for backwards compatibility with
  /// MaterialApp.theme checks; [resolvedTheme] supplies dialog & surface theming
  /// for all 18 built-in and custom palettes.
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

  /// Full brightness-matched Material theme for dialogs, system bars, and
  /// controls across all 18 themes and custom palettes.
  ThemeData resolvedTheme(ThemeData base) {
    if (highContrastEnabled) return accessibilityTheme ?? base;
    final brightness = backgroundBrightness;
    final ink = readableTextColor;
    final surface = panelColor;
    final onSurface = panelTextColor;
    final scheme = (brightness == Brightness.dark
            ? const ColorScheme.dark()
            : const ColorScheme.light())
        .copyWith(
          primary: ink,
          onPrimary: backgroundColor,
          secondary: buttonColor2,
          onSecondary: readableOn(buttonColor2, textColor2),
          secondaryContainer: ink,
          onSecondaryContainer: backgroundColor,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurface,
          outline: panelBorderColor,
        );
    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(color: ink),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: ink),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlayStyle,
      ),
    );
  }

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
    try {
      final prefs = StorageManager.sharedPreferences;
      _followSystemTheme = prefs?.get(kFollowSystemTheme) == true;
      final savedLight = prefs?.get(kLightThemeIndex);
      if (savedLight is int && savedLight >= 0 && savedLight <= 17) {
        _lightThemeIndex = savedLight;
      }
      final savedDark = prefs?.get(kDarkThemeIndex);
      if (savedDark is int && savedDark >= 0 && savedDark <= 17) {
        _darkThemeIndex = savedDark;
      }
      _useCustomTheme = prefs?.get(kUseCustomTheme) == true;
      final rawCustom = prefs?.get(kCustomThemePalette);
      if (rawCustom is String) {
        final parsed = CustomThemePalette.fromJson(jsonDecode(rawCustom));
        if (parsed != null) _customPalette = parsed;
      }
    } catch (error) {
      debugPrint('Extended theme preferences unavailable: $error');
    }
    _changeTheme();
  }

  void updatePlatformBrightness(Brightness brightness) {
    if (_platformBrightness == brightness) return;
    _platformBrightness = brightness;
    if (_followSystemTheme && !_useCustomTheme && !_highContrastEnabled) {
      _changeTheme();
      notifyListeners();
    }
  }

  /// 切换指定色彩
  void switchTheme(int colorIndex) {
    if (colorIndex < 0 || colorIndex > 17) return;
    _themeColor = colorIndex;
    _useCustomTheme = false;
    _followSystemTheme = false;
    _changeTheme();
    notifyListeners();
    unawaited(StorageManager.saveInt(kThemeColorIndex, colorIndex));
    unawaited(_saveBool(kUseCustomTheme, false));
    unawaited(_saveBool(kFollowSystemTheme, false));
  }

  void setFollowSystemTheme(bool enabled) {
    if (_followSystemTheme == enabled) return;
    _followSystemTheme = enabled;
    if (enabled) _useCustomTheme = false;
    _changeTheme();
    notifyListeners();
    unawaited(_saveBool(kFollowSystemTheme, enabled));
    if (enabled) unawaited(_saveBool(kUseCustomTheme, false));
  }

  void setLightThemeIndex(int index) {
    if (index < 0 || index > 17 || _lightThemeIndex == index) return;
    _lightThemeIndex = index;
    if (_followSystemTheme) _changeTheme();
    notifyListeners();
    unawaited(StorageManager.saveInt(kLightThemeIndex, index));
  }

  void setDarkThemeIndex(int index) {
    if (index < 0 || index > 17 || _darkThemeIndex == index) return;
    _darkThemeIndex = index;
    if (_followSystemTheme) _changeTheme();
    notifyListeners();
    unawaited(StorageManager.saveInt(kDarkThemeIndex, index));
  }

  void setCustomPalette(CustomThemePalette palette, {bool activate = true}) {
    _customPalette = palette;
    if (activate) {
      _useCustomTheme = true;
      _followSystemTheme = false;
    }
    _changeTheme();
    notifyListeners();
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs != null) {
        unawaited(
          prefs.setString(kCustomThemePalette, jsonEncode(palette.toJson())),
        );
        if (activate) {
          unawaited(prefs.setBool(kUseCustomTheme, true));
          unawaited(prefs.setBool(kFollowSystemTheme, false));
        }
      }
    } catch (error) {
      debugPrint('Custom theme could not be saved: $error');
    }
  }

  void setUseCustomTheme(bool enabled) {
    if (_useCustomTheme == enabled) return;
    _useCustomTheme = enabled;
    if (enabled) _followSystemTheme = false;
    _changeTheme();
    notifyListeners();
    unawaited(_saveBool(kUseCustomTheme, enabled));
    if (enabled) unawaited(_saveBool(kFollowSystemTheme, false));
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      await StorageManager.sharedPreferences?.setBool(key, value);
    } catch (error) {
      debugPrint('Theme preference could not be saved: $error');
    }
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
    if (_useCustomTheme) {
      backgroundColor = _customPalette.background;
      buttonColor1 = _customPalette.button1;
      buttonColor2 = _customPalette.button2;
      buttonColor3 = _customPalette.button3;
      textColor1 = readableOn(backgroundColor, Colors.white);
      textColor2 = readableOn(buttonColor1, Colors.white);
      return;
    }
    final index = activeThemeIndex;
    if (index == 0) {
      backgroundColor = const Color(0xffEFE4DC);
      buttonColor1 = const Color(0xffA2917E);
      buttonColor2 = const Color(0xffF39E5A);
      buttonColor3 = const Color(0xff6E5940);
      textColor1 = const Color(0xff766C64);
      textColor2 = const Color(0xffFFFFFF);
    } else if (index == 1) {
      backgroundColor = const Color(0xffEEEDF0);
      buttonColor1 = const Color(0xffCCF6F3);
      buttonColor2 = const Color(0xffFDB4CF);
      buttonColor3 = const Color(0xffFAD715);
      textColor1 = const Color(0xff63515D);
      textColor2 = const Color(0xff445458);
    } else if (index == 2) {
      backgroundColor = const Color(0xffEEEDF0);
      buttonColor1 = const Color(0xffEEEDEF);
      buttonColor2 = const Color(0xff3D837C);
      buttonColor3 = const Color(0xff438DF2);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (index == 3) {
      backgroundColor = const Color(0xff3B343F);
      buttonColor1 = const Color(0xffF0ECE2);
      buttonColor2 = const Color(0xff505469);
      buttonColor3 = const Color(0xffC15851);
      textColor1 = const Color(0xffFCFBFC);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 4) {
      backgroundColor = const Color(0xffFFFFFF);
      buttonColor1 = const Color(0xffEDD6E9);
      buttonColor2 = const Color(0xffA8CDDD);
      buttonColor3 = const Color(0xffBDACD6);
      textColor1 = const Color(0xff241003);
      textColor2 = const Color(0xff241003);
    } else if (index == 5) {
      backgroundColor = const Color(0xffF6E9B6);
      buttonColor1 = const Color(0xffF4B15E);
      buttonColor2 = const Color(0xffF1C4C5);
      buttonColor3 = const Color(0xffE59791);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (index == 6) {
      backgroundColor = const Color(0xffFCFEEC);
      buttonColor1 = const Color(0xffFDEDDE);
      buttonColor2 = const Color(0xffADCFE1);
      buttonColor3 = const Color(0xffCDA7A5);
      textColor1 = const Color(0xff303740);
      textColor2 = const Color(0xff303740);
    } else if (index == 7) {
      backgroundColor = const Color(0xff277AC0);
      buttonColor1 = const Color(0xffFECA45);
      buttonColor2 = const Color(0xffFFF2CF);
      buttonColor3 = const Color(0xffFD8400);
      textColor1 = const Color(0xffFFF2CF);
      textColor2 = const Color(0xff303740);
    } else if (index == 8) {
      backgroundColor = const Color(0xff2E303E);
      buttonColor1 = const Color(0xffEBE5CF);
      buttonColor2 = const Color(0xffC1432F);
      buttonColor3 = const Color(0xff61938A);
      textColor1 = const Color(0xffF0ECE2);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 9) {
      backgroundColor = const Color(0xffE69A8E);
      buttonColor1 = const Color(0xffDCE3C1);
      buttonColor2 = const Color(0xffECE0A8);
      buttonColor3 = const Color(0xffFCD9C5);
      textColor1 = const Color(0xffF0ECE2);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 10) {
      backgroundColor = const Color(0xffFAFEE7);
      buttonColor1 = const Color(0xffEC4761);
      buttonColor2 = const Color(0xff2A3367);
      buttonColor3 = const Color(0xffBAD6E8);
      textColor1 = const Color(0xff3B343F);
      textColor2 = const Color(0xffFAFEE7);
    } else if (index == 11) {
      backgroundColor = const Color(0xff9F6697);
      buttonColor1 = const Color(0xffF8D36E);
      buttonColor2 = const Color(0xffF8826C);
      buttonColor3 = const Color(0xff7EB5A1);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 12) {
      backgroundColor = const Color(0xffE1218A);
      buttonColor1 = const Color(0xff68D1FB);
      buttonColor2 = const Color(0xffF3E0E6);
      buttonColor3 = const Color(0xffFC88C1);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 13) {
      backgroundColor = const Color(0xffF08347);
      buttonColor1 = const Color(0xffFCCE91);
      buttonColor2 = const Color(0xff68D1FB);
      buttonColor3 = const Color(0xffF5F5DC);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 14) {
      backgroundColor = const Color(0xff81D975);
      buttonColor1 = const Color(0xffD2FAB8);
      buttonColor2 = const Color(0xffFFE7ED);
      buttonColor3 = const Color(0xff5ED5DE);
      textColor1 = const Color(0xff3B343F);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 15) {
      backgroundColor = const Color(0xffA01C12);
      buttonColor1 = const Color(0xffFEBB26);
      buttonColor2 = const Color(0xffECC282);
      buttonColor3 = const Color(0xff976A61);
      textColor1 = const Color(0xffFAFEE7);
      textColor2 = const Color(0xff3B343F);
    } else if (index == 16) {
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
