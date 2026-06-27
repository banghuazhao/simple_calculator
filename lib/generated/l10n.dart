// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `More`
  String get More {
    return Intl.message('More', name: 'More', desc: '', args: []);
  }

  /// `More Apps`
  String get MoreApps {
    return Intl.message('More Apps', name: 'MoreApps', desc: '', args: []);
  }

  /// `Classic Memory Game`
  String get Classic_Memory_Game {
    return Intl.message(
      'Classic Memory Game',
      name: 'Classic_Memory_Game',
      desc: '',
      args: [],
    );
  }

  /// `Shows`
  String get Shows {
    return Intl.message('Shows', name: 'Shows', desc: '', args: []);
  }

  /// `Classic 15 Puzzle`
  String get Classic_15_Puzzle {
    return Intl.message(
      'Classic 15 Puzzle',
      name: 'Classic_15_Puzzle',
      desc: '',
      args: [],
    );
  }

  /// `Relaxing Up`
  String get Relaxing_Up {
    return Intl.message('Relaxing Up', name: 'Relaxing_Up', desc: '', args: []);
  }

  /// `Falling Block Puzzle`
  String get Falling_Block_Puzzle {
    return Intl.message(
      'Falling Block Puzzle',
      name: 'Falling_Block_Puzzle',
      desc: '',
      args: [],
    );
  }

  /// `Onlynote`
  String get Onlynote {
    return Intl.message('Onlynote', name: 'Onlynote', desc: '', args: []);
  }

  /// `Easy Unit`
  String get Easy_Unit {
    return Intl.message('Easy Unit', name: 'Easy_Unit', desc: '', args: []);
  }

  /// `World Weather Live`
  String get World_Weather_Live {
    return Intl.message(
      'World Weather Live',
      name: 'World_Weather_Live',
      desc: '',
      args: [],
    );
  }

  /// `Simple Calculator`
  String get Simple_Calculator {
    return Intl.message(
      'Simple Calculator',
      name: 'Simple_Calculator',
      desc: '',
      args: [],
    );
  }

  /// `Simple English Dictionary`
  String get Simple_English_Dictionary {
    return Intl.message(
      'Simple English Dictionary',
      name: 'Simple_English_Dictionary',
      desc: '',
      args: [],
    );
  }

  /// `Classic Reversi`
  String get Classic_Reversi {
    return Intl.message(
      'Classic Reversi',
      name: 'Classic_Reversi',
      desc: '',
      args: [],
    );
  }

  /// `Garden: Catch Bugs`
  String get Garden_Catch_Bugs {
    return Intl.message(
      'Garden: Catch Bugs',
      name: 'Garden_Catch_Bugs',
      desc: '',
      args: [],
    );
  }

  /// `Space Jumper`
  String get Space_Jumper {
    return Intl.message(
      'Space Jumper',
      name: 'Space_Jumper',
      desc: '',
      args: [],
    );
  }

  /// `Crazy Pyramid`
  String get Crazy_Pyramid {
    return Intl.message(
      'Crazy Pyramid',
      name: 'Crazy_Pyramid',
      desc: '',
      args: [],
    );
  }

  /// `Classic 2048`
  String get Classic_2048 {
    return Intl.message(
      'Classic 2048',
      name: 'Classic_2048',
      desc: '',
      args: [],
    );
  }

  /// `Classic Minesweeper`
  String get Classic_Minesweeper {
    return Intl.message(
      'Classic Minesweeper',
      name: 'Classic_Minesweeper',
      desc: '',
      args: [],
    );
  }

  /// `Image Guru`
  String get Image_Guru {
    return Intl.message('Image Guru', name: 'Image_Guru', desc: '', args: []);
  }

  /// `Solitaire Guru`
  String get Solitaire_Guru {
    return Intl.message(
      'Solitaire Guru',
      name: 'Solitaire_Guru',
      desc: '',
      args: [],
    );
  }

  /// `Yes Habit`
  String get Yes_Habit {
    return Intl.message('Yes Habit', name: 'Yes_Habit', desc: '', args: []);
  }

  /// `Instant Face`
  String get Instant_Face {
    return Intl.message(
      'Instant Face',
      name: 'Instant_Face',
      desc: '',
      args: [],
    );
  }

  /// `Saving Ambulance`
  String get Saving_Ambulance {
    return Intl.message(
      'Saving Ambulance',
      name: 'Saving_Ambulance',
      desc: '',
      args: [],
    );
  }

  /// `Fling Knife`
  String get Fling_Knife {
    return Intl.message('Fling Knife', name: 'Fling_Knife', desc: '', args: []);
  }

  /// `TripMark`
  String get TripMark {
    return Intl.message('TripMark', name: 'TripMark', desc: '', args: []);
  }

  /// `Flappy Fish`
  String get Flappy_Fish {
    return Intl.message('Flappy Fish', name: 'Flappy_Fish', desc: '', args: []);
  }

  /// `Sudoku Lovers`
  String get Sudoku_Lovers {
    return Intl.message(
      'Sudoku Lovers',
      name: 'Sudoku_Lovers',
      desc: '',
      args: [],
    );
  }

  /// `Classic Tic Tac Toe`
  String get Classic_Tic_Tac_Toe {
    return Intl.message(
      'Classic Tic Tac Toe',
      name: 'Classic_Tic_Tac_Toe',
      desc: '',
      args: [],
    );
  }

  /// `We Play Piano`
  String get We_Play_Piano {
    return Intl.message(
      'We Play Piano',
      name: 'We_Play_Piano',
      desc: '',
      args: [],
    );
  }

  /// `Minesweeper Go`
  String get Minesweeper_Go {
    return Intl.message(
      'Minesweeper Go',
      name: 'Minesweeper_Go',
      desc: '',
      args: [],
    );
  }

  /// `How to change the level?`
  String get How_to_change_level {
    return Intl.message(
      'How to change the level?',
      name: 'How_to_change_level',
      desc: '',
      args: [],
    );
  }

  /// `You can change the level by taping the right/left button before the game start or after click Reset button.`
  String get How_to_change_level_explain {
    return Intl.message(
      'You can change the level by taping the right/left button before the game start or after click Reset button.',
      name: 'How_to_change_level_explain',
      desc: '',
      args: [],
    );
  }

  /// `Background Music`
  String get background_music {
    return Intl.message(
      'Background Music',
      name: 'background_music',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'HK'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
