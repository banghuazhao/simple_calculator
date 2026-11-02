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

  /// `History`
  String get history {
    return Intl.message('History', name: 'history', desc: '', args: []);
  }

  /// `Clear history?`
  String get clearHistoryTitle {
    return Intl.message(
      'Clear history?',
      name: 'clearHistoryTitle',
      desc: '',
      args: [],
    );
  }

  /// `This will remove all saved calculations.`
  String get clearHistoryMessage {
    return Intl.message(
      'This will remove all saved calculations.',
      name: 'clearHistoryMessage',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Clear`
  String get clear {
    return Intl.message('Clear', name: 'clear', desc: '', args: []);
  }

  /// `No calculations yet`
  String get noCalculationsYet {
    return Intl.message(
      'No calculations yet',
      name: 'noCalculationsYet',
      desc: '',
      args: [],
    );
  }

  /// `Copied`
  String get copied {
    return Intl.message('Copied', name: 'copied', desc: '', args: []);
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Undo`
  String get undo {
    return Intl.message('Undo', name: 'undo', desc: '', args: []);
  }

  /// `Clear input`
  String get clearInput {
    return Intl.message('Clear input', name: 'clearInput', desc: '', args: []);
  }

  /// `Change sign`
  String get changeSign {
    return Intl.message('Change sign', name: 'changeSign', desc: '', args: []);
  }

  /// `Percent`
  String get percent {
    return Intl.message('Percent', name: 'percent', desc: '', args: []);
  }

  /// `Divide`
  String get divide {
    return Intl.message('Divide', name: 'divide', desc: '', args: []);
  }

  /// `Multiply`
  String get multiply {
    return Intl.message('Multiply', name: 'multiply', desc: '', args: []);
  }

  /// `Subtract`
  String get subtract {
    return Intl.message('Subtract', name: 'subtract', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Equals`
  String get equals {
    return Intl.message('Equals', name: 'equals', desc: '', args: []);
  }

  /// `Decimal point`
  String get decimalPoint {
    return Intl.message(
      'Decimal point',
      name: 'decimalPoint',
      desc: '',
      args: [],
    );
  }

  /// `Backspace`
  String get backspace {
    return Intl.message('Backspace', name: 'backspace', desc: '', args: []);
  }

  /// `Copy result`
  String get copyResult {
    return Intl.message('Copy result', name: 'copyResult', desc: '', args: []);
  }

  /// `Error`
  String get error {
    return Intl.message('Error', name: 'error', desc: '', args: []);
  }

  /// `Use this result`
  String get reuseResult {
    return Intl.message(
      'Use this result',
      name: 'reuseResult',
      desc: '',
      args: [],
    );
  }

  /// `Delete calculation`
  String get deleteCalculation {
    return Intl.message(
      'Delete calculation',
      name: 'deleteCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Copy calculation`
  String get copyCalculation {
    return Intl.message(
      'Copy calculation',
      name: 'copyCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Input settings`
  String get inputSettings {
    return Intl.message(
      'Input settings',
      name: 'inputSettings',
      desc: '',
      args: [],
    );
  }

  /// `Haptic feedback`
  String get hapticFeedback {
    return Intl.message(
      'Haptic feedback',
      name: 'hapticFeedback',
      desc: '',
      args: [],
    );
  }

  /// `Vibrate when using calculator controls`
  String get hapticFeedbackDescription {
    return Intl.message(
      'Vibrate when using calculator controls',
      name: 'hapticFeedbackDescription',
      desc: '',
      args: [],
    );
  }

  /// `Shake to undo`
  String get shakeToUndo {
    return Intl.message(
      'Shake to undo',
      name: 'shakeToUndo',
      desc: '',
      args: [],
    );
  }

  /// `Undo the last input by shaking your phone`
  String get shakeToUndoDescription {
    return Intl.message(
      'Undo the last input by shaking your phone',
      name: 'shakeToUndoDescription',
      desc: '',
      args: [],
    );
  }

  /// `Tips and shortcuts`
  String get helpAndShortcuts {
    return Intl.message(
      'Tips and shortcuts',
      name: 'helpAndShortcuts',
      desc: '',
      args: [],
    );
  }

  /// `Using the calculator`
  String get helpBasics {
    return Intl.message(
      'Using the calculator',
      name: 'helpBasics',
      desc: '',
      args: [],
    );
  }

  /// `Tap the result to copy the number. Use the copy button in history to copy a full calculation.`
  String get helpCopy {
    return Intl.message(
      'Tap the result to copy the number. Use the copy button in history to copy a full calculation.',
      name: 'helpCopy',
      desc: '',
      args: [],
    );
  }

  /// `Use Undo to restore recent input. Shake-to-undo and haptic feedback can be changed in Input settings.`
  String get helpUndo {
    return Intl.message(
      'Use Undo to restore recent input. Shake-to-undo and haptic feedback can be changed in Input settings.',
      name: 'helpUndo',
      desc: '',
      args: [],
    );
  }

  /// `History keeps up to 100 calculations. Tap an entry to reuse its result, swipe to delete it, or use Undo after deletion.`
  String get helpHistory {
    return Intl.message(
      'History keeps up to 100 calculations. Tap an entry to reuse its result, swipe to delete it, or use Undo after deletion.',
      name: 'helpHistory',
      desc: '',
      args: [],
    );
  }

  /// `Keyboard shortcuts`
  String get helpKeyboard {
    return Intl.message(
      'Keyboard shortcuts',
      name: 'helpKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `Numbers and numeric keypad`
  String get shortcutNumbers {
    return Intl.message(
      'Numbers and numeric keypad',
      name: 'shortcutNumbers',
      desc: '',
      args: [],
    );
  }

  /// `Add, subtract, multiply, divide, percent, and decimal point`
  String get shortcutOperators {
    return Intl.message(
      'Add, subtract, multiply, divide, percent, and decimal point',
      name: 'shortcutOperators',
      desc: '',
      args: [],
    );
  }

  /// `Calculate`
  String get shortcutEquals {
    return Intl.message(
      'Calculate',
      name: 'shortcutEquals',
      desc: '',
      args: [],
    );
  }

  /// `Delete the last digit`
  String get shortcutBackspace {
    return Intl.message(
      'Delete the last digit',
      name: 'shortcutBackspace',
      desc: '',
      args: [],
    );
  }

  /// `Clear input`
  String get shortcutClear {
    return Intl.message(
      'Clear input',
      name: 'shortcutClear',
      desc: '',
      args: [],
    );
  }

  /// `Undo input`
  String get shortcutUndo {
    return Intl.message('Undo input', name: 'shortcutUndo', desc: '', args: []);
  }

  /// `Paste a number`
  String get shortcutPaste {
    return Intl.message(
      'Paste a number',
      name: 'shortcutPaste',
      desc: '',
      args: [],
    );
  }

  /// `Paste accepts a single finite number, including correctly grouped thousands or scientific notation. Expressions and other text are rejected.`
  String get helpPaste {
    return Intl.message(
      'Paste accepts a single finite number, including correctly grouped thousands or scientific notation. Expressions and other text are rejected.',
      name: 'helpPaste',
      desc: '',
      args: [],
    );
  }

  /// `Search history`
  String get searchHistory {
    return Intl.message(
      'Search history',
      name: 'searchHistory',
      desc: '',
      args: [],
    );
  }

  /// `Clear search`
  String get clearSearch {
    return Intl.message(
      'Clear search',
      name: 'clearSearch',
      desc: '',
      args: [],
    );
  }

  /// `No matching calculations`
  String get noHistoryMatches {
    return Intl.message(
      'No matching calculations',
      name: 'noHistoryMatches',
      desc: '',
      args: [],
    );
  }

  /// `Clear all`
  String get clearAllHistory {
    return Intl.message(
      'Clear all',
      name: 'clearAllHistory',
      desc: '',
      args: [],
    );
  }

  /// `Calculation deleted`
  String get historyDeleted {
    return Intl.message(
      'Calculation deleted',
      name: 'historyDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Paste number`
  String get pasteNumber {
    return Intl.message(
      'Paste number',
      name: 'pasteNumber',
      desc: '',
      args: [],
    );
  }

  /// `Number pasted`
  String get pasted {
    return Intl.message('Number pasted', name: 'pasted', desc: '', args: []);
  }

  /// `Copy a valid number to paste.`
  String get invalidPaste {
    return Intl.message(
      'Copy a valid number to paste.',
      name: 'invalidPaste',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard is unavailable. Please try again.`
  String get clipboardUnavailable {
    return Intl.message(
      'Clipboard is unavailable. Please try again.',
      name: 'clipboardUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Copy all history`
  String get copyAllHistory {
    return Intl.message(
      'Copy all history',
      name: 'copyAllHistory',
      desc: '',
      args: [],
    );
  }

  /// `Copy matching calculations`
  String get copyMatchingHistory {
    return Intl.message(
      'Copy matching calculations',
      name: 'copyMatchingHistory',
      desc: '',
      args: [],
    );
  }

  /// `High contrast`
  String get highContrast {
    return Intl.message(
      'High contrast',
      name: 'highContrast',
      desc: '',
      args: [],
    );
  }

  /// `Use stronger contrast for numbers and controls. Your selected theme is kept.`
  String get highContrastDescription {
    return Intl.message(
      'Use stronger contrast for numbers and controls. Your selected theme is kept.',
      name: 'highContrastDescription',
      desc: '',
      args: [],
    );
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
