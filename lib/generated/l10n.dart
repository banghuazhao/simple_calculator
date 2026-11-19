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

  /// `Calculation actions`
  String get historyEntryActions {
    return Intl.message(
      'Calculation actions',
      name: 'historyEntryActions',
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

  /// `Tap the result to copy the number. After pressing =, use the copy button beside the equation to copy the full calculation.`
  String get helpCopy {
    return Intl.message(
      'Tap the result to copy the number. After pressing =, use the copy button beside the equation to copy the full calculation.',
      name: 'helpCopy',
      desc: '',
      args: [],
    );
  }

  /// `Use Copy all history or Copy matching calculations for plain text. Choose Copy as TSV to paste the same entries into spreadsheet columns.`
  String get helpCopyHistory {
    return Intl.message(
      'Use Copy all history or Copy matching calculations for plain text. Choose Copy as TSV to paste the same entries into spreadsheet columns.',
      name: 'helpCopyHistory',
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

  /// `History keeps up to 100 calculations. Tap an entry to reuse its result, or choose Edit calculation from its actions menu to recalculate it. Swipe to delete, then tap Undo to restore it.`
  String get helpHistory {
    return Intl.message(
      'History keeps up to 100 calculations. Tap an entry to reuse its result, or choose Edit calculation from its actions menu to recalculate it. Swipe to delete, then tap Undo to restore it.',
      name: 'helpHistory',
      desc: '',
      args: [],
    );
  }

  /// `Tap Premium tools in the calculator toolbar to open the scientific calculator or reusable formulas.`
  String get helpPremiumShortcut {
    return Intl.message(
      'Tap Premium tools in the calculator toolbar to open the scientific calculator or reusable formulas.',
      name: 'helpPremiumShortcut',
      desc: '',
      args: [],
    );
  }

  /// `Choose Degrees or Radians in the scientific calculator before using trigonometric functions.`
  String get helpPremiumScientific {
    return Intl.message(
      'Choose Degrees or Radians in the scientific calculator before using trigonometric functions.',
      name: 'helpPremiumScientific',
      desc: '',
      args: [],
    );
  }

  /// `Open a saved formula to compare inputs. Choose Edit formula to change its expression, input labels or units, or scenario names.`
  String get helpPremiumFormulas {
    return Intl.message(
      'Open a saved formula to compare inputs. Choose Edit formula to change its expression, input labels or units, or scenario names.',
      name: 'helpPremiumFormulas',
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

  /// `SwiftSum Premium`
  String get premium {
    return Intl.message(
      'SwiftSum Premium',
      name: 'premium',
      desc: '',
      args: [],
    );
  }

  /// `Premium tools`
  String get premiumTools {
    return Intl.message(
      'Premium tools',
      name: 'premiumTools',
      desc: '',
      args: [],
    );
  }

  /// `Premium is active.`
  String get premiumActive {
    return Intl.message(
      'Premium is active.',
      name: 'premiumActive',
      desc: '',
      args: [],
    );
  }

  /// `A one-time purchase unlocks both tools and removes ads.`
  String get premiumOffer {
    return Intl.message(
      'A one-time purchase unlocks both tools and removes ads.',
      name: 'premiumOffer',
      desc: '',
      args: [],
    );
  }

  /// `A one-time purchase unlocks the scientific calculator and reusable formulas.`
  String get premiumOfferToolsOnly {
    return Intl.message(
      'A one-time purchase unlocks the scientific calculator and reusable formulas.',
      name: 'premiumOfferToolsOnly',
      desc: '',
      args: [],
    );
  }

  /// `What-if preview`
  String get premiumWhatIfPreview {
    return Intl.message(
      'What-if preview',
      name: 'premiumWhatIfPreview',
      desc: '',
      args: [],
    );
  }

  /// `Start with a price of $100.`
  String get premiumWhatIfPrice {
    return Intl.message(
      'Start with a price of \$100.',
      name: 'premiumWhatIfPrice',
      desc: '',
      args: [],
    );
  }

  /// `With 10% off, you pay $90.`
  String get premiumWhatIfBaseline {
    return Intl.message(
      'With 10% off, you pay \$90.',
      name: 'premiumWhatIfBaseline',
      desc: '',
      args: [],
    );
  }

  /// `With 25% off, you pay $75.`
  String get premiumWhatIfAlternate {
    return Intl.message(
      'With 25% off, you pay \$75.',
      name: 'premiumWhatIfAlternate',
      desc: '',
      args: [],
    );
  }

  /// `Ad-free calculator`
  String get premiumAdFree {
    return Intl.message(
      'Ad-free calculator',
      name: 'premiumAdFree',
      desc: '',
      args: [],
    );
  }

  /// `Buy Premium`
  String get premiumBuy {
    return Intl.message('Buy Premium', name: 'premiumBuy', desc: '', args: []);
  }

  /// `Check App Store price`
  String get premiumCheckPrice {
    return Intl.message(
      'Check App Store price',
      name: 'premiumCheckPrice',
      desc: '',
      args: [],
    );
  }

  /// `Check Google Play price`
  String get premiumCheckPriceGooglePlay {
    return Intl.message(
      'Check Google Play price',
      name: 'premiumCheckPriceGooglePlay',
      desc: '',
      args: [],
    );
  }

  /// `Restore purchases`
  String get premiumRestore {
    return Intl.message(
      'Restore purchases',
      name: 'premiumRestore',
      desc: '',
      args: [],
    );
  }

  /// `Premium purchase restored.`
  String get premiumRestored {
    return Intl.message(
      'Premium purchase restored.',
      name: 'premiumRestored',
      desc: '',
      args: [],
    );
  }

  /// `The purchase is waiting for approval.`
  String get premiumPending {
    return Intl.message(
      'The purchase is waiting for approval.',
      name: 'premiumPending',
      desc: '',
      args: [],
    );
  }

  /// `No Premium purchase was found for this Apple Account.`
  String get premiumNotPurchased {
    return Intl.message(
      'No Premium purchase was found for this Apple Account.',
      name: 'premiumNotPurchased',
      desc: '',
      args: [],
    );
  }

  /// `No Premium purchase was found for this Google account.`
  String get premiumNotPurchasedGooglePlay {
    return Intl.message(
      'No Premium purchase was found for this Google account.',
      name: 'premiumNotPurchasedGooglePlay',
      desc: '',
      args: [],
    );
  }

  /// `Premium is temporarily unavailable.`
  String get premiumUnavailable {
    return Intl.message(
      'Premium is temporarily unavailable.',
      name: 'premiumUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `The App Store couldn’t complete the request. Try again.`
  String get premiumFailed {
    return Intl.message(
      'The App Store couldn’t complete the request. Try again.',
      name: 'premiumFailed',
      desc: '',
      args: [],
    );
  }

  /// `Google Play couldn’t complete the request. Try again.`
  String get premiumFailedGooglePlay {
    return Intl.message(
      'Google Play couldn’t complete the request. Try again.',
      name: 'premiumFailedGooglePlay',
      desc: '',
      args: [],
    );
  }

  /// `Scientific calculator`
  String get scientificCalculator {
    return Intl.message(
      'Scientific calculator',
      name: 'scientificCalculator',
      desc: '',
      args: [],
    );
  }

  /// `Expression`
  String get scientificExpression {
    return Intl.message(
      'Expression',
      name: 'scientificExpression',
      desc: '',
      args: [],
    );
  }

  /// `Use * for multiplication. Try 2 * sin(30) + sqrt(9).`
  String get scientificExpressionHelp {
    return Intl.message(
      'Use * for multiplication. Try 2 * sin(30) + sqrt(9).',
      name: 'scientificExpressionHelp',
      desc: '',
      args: [],
    );
  }

  /// `Degrees`
  String get scientificDegrees {
    return Intl.message(
      'Degrees',
      name: 'scientificDegrees',
      desc: '',
      args: [],
    );
  }

  /// `Radians`
  String get scientificRadians {
    return Intl.message(
      'Radians',
      name: 'scientificRadians',
      desc: '',
      args: [],
    );
  }

  /// `Calculate`
  String get scientificEvaluate {
    return Intl.message(
      'Calculate',
      name: 'scientificEvaluate',
      desc: '',
      args: [],
    );
  }

  /// `Result`
  String get scientificResult {
    return Intl.message('Result', name: 'scientificResult', desc: '', args: []);
  }

  /// `Enter a valid expression with a finite result.`
  String get scientificInvalidExpression {
    return Intl.message(
      'Enter a valid expression with a finite result.',
      name: 'scientificInvalidExpression',
      desc: '',
      args: [],
    );
  }

  /// `Reusable formulas`
  String get reusableFormulas {
    return Intl.message(
      'Reusable formulas',
      name: 'reusableFormulas',
      desc: '',
      args: [],
    );
  }

  /// `New formula`
  String get formulaNew {
    return Intl.message('New formula', name: 'formulaNew', desc: '', args: []);
  }

  /// `Formula examples`
  String get formulaExamples {
    return Intl.message(
      'Formula examples',
      name: 'formulaExamples',
      desc: '',
      args: [],
    );
  }

  /// `Order total`
  String get formulaExampleOrderTotal {
    return Intl.message(
      'Order total',
      name: 'formulaExampleOrderTotal',
      desc: '',
      args: [],
    );
  }

  /// `Discounted price`
  String get formulaExampleDiscount {
    return Intl.message(
      'Discounted price',
      name: 'formulaExampleDiscount',
      desc: '',
      args: [],
    );
  }

  /// `Price with tax`
  String get formulaExampleTax {
    return Intl.message(
      'Price with tax',
      name: 'formulaExampleTax',
      desc: '',
      args: [],
    );
  }

  /// `Edit formula`
  String get formulaEdit {
    return Intl.message(
      'Edit formula',
      name: 'formulaEdit',
      desc: '',
      args: [],
    );
  }

  /// `Formula name`
  String get formulaName {
    return Intl.message(
      'Formula name',
      name: 'formulaName',
      desc: '',
      args: [],
    );
  }

  /// `Expression`
  String get formulaExpression {
    return Intl.message(
      'Expression',
      name: 'formulaExpression',
      desc: '',
      args: [],
    );
  }

  /// `Example: price * quantity`
  String get formulaExpressionHint {
    return Intl.message(
      'Example: price * quantity',
      name: 'formulaExpressionHint',
      desc: '',
      args: [],
    );
  }

  /// `Baseline`
  String get formulaBaseline {
    return Intl.message(
      'Baseline',
      name: 'formulaBaseline',
      desc: '',
      args: [],
    );
  }

  /// `Alternate`
  String get formulaAlternate {
    return Intl.message(
      'Alternate',
      name: 'formulaAlternate',
      desc: '',
      args: [],
    );
  }

  /// `Difference (alternate − baseline)`
  String get formulaDifference {
    return Intl.message(
      'Difference (alternate − baseline)',
      name: 'formulaDifference',
      desc: '',
      args: [],
    );
  }

  /// `Copy comparison`
  String get formulaCopyComparison {
    return Intl.message(
      'Copy comparison',
      name: 'formulaCopyComparison',
      desc: '',
      args: [],
    );
  }

  /// `No formulas saved yet.`
  String get formulaEmpty {
    return Intl.message(
      'No formulas saved yet.',
      name: 'formulaEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid expression.`
  String get formulaInvalidExpression {
    return Intl.message(
      'Enter a valid expression.',
      name: 'formulaInvalidExpression',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid number.`
  String get formulaInvalidInput {
    return Intl.message(
      'Enter a valid number.',
      name: 'formulaInvalidInput',
      desc: '',
      args: [],
    );
  }

  /// `Enter a formula name.`
  String get formulaInvalidName {
    return Intl.message(
      'Enter a formula name.',
      name: 'formulaInvalidName',
      desc: '',
      args: [],
    );
  }

  /// `No result`
  String get formulaNoResult {
    return Intl.message(
      'No result',
      name: 'formulaNoResult',
      desc: '',
      args: [],
    );
  }

  /// `Could not save formulas.`
  String get formulaSaveFailed {
    return Intl.message(
      'Could not save formulas.',
      name: 'formulaSaveFailed',
      desc: '',
      args: [],
    );
  }

  /// `You can save up to 30 formulas.`
  String get formulaLimitReached {
    return Intl.message(
      'You can save up to 30 formulas.',
      name: 'formulaLimitReached',
      desc: '',
      args: [],
    );
  }

  /// `Use at most 12 named inputs.`
  String get formulaTooManyInputs {
    return Intl.message(
      'Use at most 12 named inputs.',
      name: 'formulaTooManyInputs',
      desc: '',
      args: [],
    );
  }

  /// `Delete formula`
  String get formulaDelete {
    return Intl.message(
      'Delete formula',
      name: 'formulaDelete',
      desc: '',
      args: [],
    );
  }

  /// `Delete this saved formula?`
  String get formulaDeleteMessage {
    return Intl.message(
      'Delete this saved formula?',
      name: 'formulaDeleteMessage',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get formulaSave {
    return Intl.message('Save', name: 'formulaSave', desc: '', args: []);
  }

  /// `Unit converter`
  String get unitConverter {
    return Intl.message(
      'Unit converter',
      name: 'unitConverter',
      desc: '',
      args: [],
    );
  }

  /// `Length`
  String get converterLength {
    return Intl.message('Length', name: 'converterLength', desc: '', args: []);
  }

  /// `Mass`
  String get converterMass {
    return Intl.message('Mass', name: 'converterMass', desc: '', args: []);
  }

  /// `Volume`
  String get converterVolume {
    return Intl.message('Volume', name: 'converterVolume', desc: '', args: []);
  }

  /// `Temperature`
  String get converterTemperature {
    return Intl.message(
      'Temperature',
      name: 'converterTemperature',
      desc: '',
      args: [],
    );
  }

  /// `Value`
  String get converterAmount {
    return Intl.message('Value', name: 'converterAmount', desc: '', args: []);
  }

  /// `From`
  String get converterFrom {
    return Intl.message('From', name: 'converterFrom', desc: '', args: []);
  }

  /// `To`
  String get converterTo {
    return Intl.message('To', name: 'converterTo', desc: '', args: []);
  }

  /// `Swap units`
  String get converterSwap {
    return Intl.message(
      'Swap units',
      name: 'converterSwap',
      desc: '',
      args: [],
    );
  }

  /// `Metres`
  String get converterMeter {
    return Intl.message('Metres', name: 'converterMeter', desc: '', args: []);
  }

  /// `Feet`
  String get converterFoot {
    return Intl.message('Feet', name: 'converterFoot', desc: '', args: []);
  }

  /// `Centimetres`
  String get converterCentimeter {
    return Intl.message(
      'Centimetres',
      name: 'converterCentimeter',
      desc: '',
      args: [],
    );
  }

  /// `Inches`
  String get converterInch {
    return Intl.message('Inches', name: 'converterInch', desc: '', args: []);
  }

  /// `Kilometres`
  String get converterKilometer {
    return Intl.message(
      'Kilometres',
      name: 'converterKilometer',
      desc: '',
      args: [],
    );
  }

  /// `Miles`
  String get converterMile {
    return Intl.message('Miles', name: 'converterMile', desc: '', args: []);
  }

  /// `Kilograms`
  String get converterKilogram {
    return Intl.message(
      'Kilograms',
      name: 'converterKilogram',
      desc: '',
      args: [],
    );
  }

  /// `Pounds`
  String get converterPound {
    return Intl.message('Pounds', name: 'converterPound', desc: '', args: []);
  }

  /// `Grams`
  String get converterGram {
    return Intl.message('Grams', name: 'converterGram', desc: '', args: []);
  }

  /// `Ounces`
  String get converterOunce {
    return Intl.message('Ounces', name: 'converterOunce', desc: '', args: []);
  }

  /// `Milligrams`
  String get converterMilligram {
    return Intl.message(
      'Milligrams',
      name: 'converterMilligram',
      desc: '',
      args: [],
    );
  }

  /// `Litres`
  String get converterLiter {
    return Intl.message('Litres', name: 'converterLiter', desc: '', args: []);
  }

  /// `US gallons`
  String get converterUsGallon {
    return Intl.message(
      'US gallons',
      name: 'converterUsGallon',
      desc: '',
      args: [],
    );
  }

  /// `Millilitres`
  String get converterMilliliter {
    return Intl.message(
      'Millilitres',
      name: 'converterMilliliter',
      desc: '',
      args: [],
    );
  }

  /// `US cups`
  String get converterUsCup {
    return Intl.message('US cups', name: 'converterUsCup', desc: '', args: []);
  }

  /// `US fluid ounces`
  String get converterUsFluidOunce {
    return Intl.message(
      'US fluid ounces',
      name: 'converterUsFluidOunce',
      desc: '',
      args: [],
    );
  }

  /// `Celsius`
  String get converterCelsius {
    return Intl.message(
      'Celsius',
      name: 'converterCelsius',
      desc: '',
      args: [],
    );
  }

  /// `Fahrenheit`
  String get converterFahrenheit {
    return Intl.message(
      'Fahrenheit',
      name: 'converterFahrenheit',
      desc: '',
      args: [],
    );
  }

  /// `Kelvin`
  String get converterKelvin {
    return Intl.message('Kelvin', name: 'converterKelvin', desc: '', args: []);
  }

  /// `Edit calculation`
  String get historyEditCalculation {
    return Intl.message(
      'Edit calculation',
      name: 'historyEditCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Copy as TSV`
  String get historyCopyAsTsv {
    return Intl.message(
      'Copy as TSV',
      name: 'historyCopyAsTsv',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid arithmetic expression.`
  String get historyInvalidExpression {
    return Intl.message(
      'Enter a valid arithmetic expression.',
      name: 'historyInvalidExpression',
      desc: '',
      args: [],
    );
  }

  /// `Try (2 + 3) × 4 or 200 + 10%.`
  String get historyExpressionHelp {
    return Intl.message(
      'Try (2 + 3) × 4 or 200 + 10%.',
      name: 'historyExpressionHelp',
      desc: '',
      args: [],
    );
  }

  /// `Customize labels and scenarios`
  String get formulaCustomize {
    return Intl.message(
      'Customize labels and scenarios',
      name: 'formulaCustomize',
      desc: '',
      args: [],
    );
  }

  /// `Input label`
  String get formulaInputLabel {
    return Intl.message(
      'Input label',
      name: 'formulaInputLabel',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get formulaInputUnit {
    return Intl.message('Unit', name: 'formulaInputUnit', desc: '', args: []);
  }

  /// `Baseline scenario name`
  String get formulaBaselineName {
    return Intl.message(
      'Baseline scenario name',
      name: 'formulaBaselineName',
      desc: '',
      args: [],
    );
  }

  /// `Alternate scenario name`
  String get formulaAlternateName {
    return Intl.message(
      'Alternate scenario name',
      name: 'formulaAlternateName',
      desc: '',
      args: [],
    );
  }

  /// `Difference ({alternate} − {baseline})`
  String formulaNamedDifference(String alternate, String baseline) {
    return Intl.message(
      'Difference ($alternate − $baseline)',
      name: 'formulaNamedDifference',
      desc: '',
      args: [alternate, baseline],
    );
  }

  /// `Use + or − with % to adjust a value by a percentage. For example, 200 + 10% = 220.`
  String get helpPercent {
    return Intl.message(
      'Use + or − with % to adjust a value by a percentage. For example, 200 + 10% = 220.',
      name: 'helpPercent',
      desc: '',
      args: [],
    );
  }

  /// `Choose Unit converter in Everyday tools, enter a value, and send the result back to the calculator.`
  String get helpConverter {
    return Intl.message(
      'Choose Unit converter in Everyday tools, enter a value, and send the result back to the calculator.',
      name: 'helpConverter',
      desc: '',
      args: [],
    );
  }

  /// `Scientific history`
  String get scientificHistory {
    return Intl.message(
      'Scientific history',
      name: 'scientificHistory',
      desc: '',
      args: [],
    );
  }

  /// `Graph`
  String get scientificGraph {
    return Intl.message('Graph', name: 'scientificGraph', desc: '', args: []);
  }

  /// `Engineering notation`
  String get scientificEngineeringNotation {
    return Intl.message(
      'Engineering notation',
      name: 'scientificEngineeringNotation',
      desc: '',
      args: [],
    );
  }

  /// `Show system keyboard`
  String get scientificShowKeyboard {
    return Intl.message(
      'Show system keyboard',
      name: 'scientificShowKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `Hide system keyboard`
  String get scientificHideKeyboard {
    return Intl.message(
      'Hide system keyboard',
      name: 'scientificHideKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `Open parenthesis`
  String get scientificOpenParenthesis {
    return Intl.message(
      'Open parenthesis',
      name: 'scientificOpenParenthesis',
      desc: '',
      args: [],
    );
  }

  /// `Close parenthesis`
  String get scientificCloseParenthesis {
    return Intl.message(
      'Close parenthesis',
      name: 'scientificCloseParenthesis',
      desc: '',
      args: [],
    );
  }

  /// `Previous answer`
  String get scientificPreviousAnswer {
    return Intl.message(
      'Previous answer',
      name: 'scientificPreviousAnswer',
      desc: '',
      args: [],
    );
  }

  /// `Scientific exponent`
  String get scientificExponentEntry {
    return Intl.message(
      'Scientific exponent',
      name: 'scientificExponentEntry',
      desc: '',
      args: [],
    );
  }

  /// `Power`
  String get scientificPower {
    return Intl.message('Power', name: 'scientificPower', desc: '', args: []);
  }

  /// `Factorial`
  String get scientificFactorial {
    return Intl.message(
      'Factorial',
      name: 'scientificFactorial',
      desc: '',
      args: [],
    );
  }

  /// `Argument separator`
  String get scientificArgumentSeparator {
    return Intl.message(
      'Argument separator',
      name: 'scientificArgumentSeparator',
      desc: '',
      args: [],
    );
  }

  /// `Check the expression near the cursor.`
  String get scientificSyntaxError {
    return Intl.message(
      'Check the expression near the cursor.',
      name: 'scientificSyntaxError',
      desc: '',
      args: [],
    );
  }

  /// `Add a closing parenthesis.`
  String get scientificMissingParen {
    return Intl.message(
      'Add a closing parenthesis.',
      name: 'scientificMissingParen',
      desc: '',
      args: [],
    );
  }

  /// `The function {name} is unknown.`
  String scientificUnknownFunction(String name) {
    return Intl.message(
      'The function $name is unknown.',
      name: 'scientificUnknownFunction',
      desc: '',
      args: [name],
    );
  }

  /// `Replace {name} with a number or Ans.`
  String scientificUnknownVariable(String name) {
    return Intl.message(
      'Replace $name with a number or Ans.',
      name: 'scientificUnknownVariable',
      desc: '',
      args: [name],
    );
  }

  /// `Calculate a result before using Ans.`
  String get scientificNoAnswer {
    return Intl.message(
      'Calculate a result before using Ans.',
      name: 'scientificNoAnswer',
      desc: '',
      args: [],
    );
  }

  /// `Change the divisor to a nonzero value.`
  String get scientificDivideByZero {
    return Intl.message(
      'Change the divisor to a nonzero value.',
      name: 'scientificDivideByZero',
      desc: '',
      args: [],
    );
  }

  /// `Check the allowed values for this operation.`
  String get scientificDomainError {
    return Intl.message(
      'Check the allowed values for this operation.',
      name: 'scientificDomainError',
      desc: '',
      args: [],
    );
  }

  /// `The result is outside the supported range.`
  String get scientificOverflow {
    return Intl.message(
      'The result is outside the supported range.',
      name: 'scientificOverflow',
      desc: '',
      args: [],
    );
  }

  /// `Shorten the expression.`
  String get scientificTooLong {
    return Intl.message(
      'Shorten the expression.',
      name: 'scientificTooLong',
      desc: '',
      args: [],
    );
  }

  /// `Use fewer nested operations.`
  String get scientificTooDeep {
    return Intl.message(
      'Use fewer nested operations.',
      name: 'scientificTooDeep',
      desc: '',
      args: [],
    );
  }

  /// `{message} (character {position})`
  String scientificErrorPosition(String message, int position) {
    return Intl.message(
      '$message (character $position)',
      name: 'scientificErrorPosition',
      desc: '',
      args: [message, position],
    );
  }

  /// `Enter a function of x, such as x^2 − 4.`
  String get graphExpressionHelp {
    return Intl.message(
      'Enter a function of x, such as x^2 − 4.',
      name: 'graphExpressionHelp',
      desc: '',
      args: [],
    );
  }

  /// `Minimum x`
  String get graphXMin {
    return Intl.message('Minimum x', name: 'graphXMin', desc: '', args: []);
  }

  /// `Maximum x`
  String get graphXMax {
    return Intl.message('Maximum x', name: 'graphXMax', desc: '', args: []);
  }

  /// `Plot`
  String get graphPlot {
    return Intl.message('Plot', name: 'graphPlot', desc: '', args: []);
  }

  /// `Find root`
  String get graphFindRoot {
    return Intl.message('Find root', name: 'graphFindRoot', desc: '', args: []);
  }

  /// `Value table`
  String get graphValueTable {
    return Intl.message(
      'Value table',
      name: 'graphValueTable',
      desc: '',
      args: [],
    );
  }

  /// `Tap or drag on the curve to inspect values.`
  String get graphPlotHint {
    return Intl.message(
      'Tap or drag on the curve to inspect values.',
      name: 'graphPlotHint',
      desc: '',
      args: [],
    );
  }

  /// `Enter a finite interval with minimum below maximum.`
  String get graphInvalidRange {
    return Intl.message(
      'Enter a finite interval with minimum below maximum.',
      name: 'graphInvalidRange',
      desc: '',
      args: [],
    );
  }

  /// `Use x and a previous answer (Ans) as variables.`
  String get graphInvalidVariables {
    return Intl.message(
      'Use x and a previous answer (Ans) as variables.',
      name: 'graphInvalidVariables',
      desc: '',
      args: [],
    );
  }

  /// `The function has no finite values in this interval.`
  String get graphNoValues {
    return Intl.message(
      'The function has no finite values in this interval.',
      name: 'graphNoValues',
      desc: '',
      args: [],
    );
  }

  /// `Choose an interval with opposite signs at its ends, or a root at an endpoint.`
  String get graphRootNeedsBracket {
    return Intl.message(
      'Choose an interval with opposite signs at its ends, or a root at an endpoint.',
      name: 'graphRootNeedsBracket',
      desc: '',
      args: [],
    );
  }

  /// `A root could not be verified. Try a smaller interval where the function is continuous.`
  String get graphRootNotFound {
    return Intl.message(
      'A root could not be verified. Try a smaller interval where the function is continuous.',
      name: 'graphRootNotFound',
      desc: '',
      args: [],
    );
  }

  /// `Undefined`
  String get graphUndefined {
    return Intl.message(
      'Undefined',
      name: 'graphUndefined',
      desc: '',
      args: [],
    );
  }

  /// `Approximate root`
  String get graphRootResult {
    return Intl.message(
      'Approximate root',
      name: 'graphRootResult',
      desc: '',
      args: [],
    );
  }

  /// `Use Ans to reuse your last scientific result, EXP to enter an exponent, and ENG to change the result format. Open Graph to plot a function, view its values, or find a root over an interval.`
  String get helpScientificAdvanced {
    return Intl.message(
      'Use Ans to reuse your last scientific result, EXP to enter an exponent, and ENG to change the result format. Open Graph to plot a function, view its values, or find a root over an interval.',
      name: 'helpScientificAdvanced',
      desc: '',
      args: [],
    );
  }

  /// `Edit first number`
  String get editFirstOperand {
    return Intl.message(
      'Edit first number',
      name: 'editFirstOperand',
      desc: '',
      args: [],
    );
  }

  /// `Edit second number`
  String get editSecondOperand {
    return Intl.message(
      'Edit second number',
      name: 'editSecondOperand',
      desc: '',
      args: [],
    );
  }

  /// `The calculation changed. Close this dialog and tap the number again.`
  String get operandChanged {
    return Intl.message(
      'The calculation changed. Close this dialog and tap the number again.',
      name: 'operandChanged',
      desc: '',
      args: [],
    );
  }

  /// `Tap either number above the main display to correct it. Use the copy button beside a completed equation to copy the calculation.`
  String get helpEditOperands {
    return Intl.message(
      'Tap either number above the main display to correct it. Use the copy button beside a completed equation to copy the calculation.',
      name: 'helpEditOperands',
      desc: '',
      args: [],
    );
  }

  /// `Open Everyday tools from the toolbar to split a bill, compare unit prices, or convert units.`
  String get helpEverydayTools {
    return Intl.message(
      'Open Everyday tools from the toolbar to split a bill, compare unit prices, or convert units.',
      name: 'helpEverydayTools',
      desc: '',
      args: [],
    );
  }

  /// `Pin calculation`
  String get historyPinCalculation {
    return Intl.message(
      'Pin calculation',
      name: 'historyPinCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Unpin calculation`
  String get historyUnpinCalculation {
    return Intl.message(
      'Unpin calculation',
      name: 'historyUnpinCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Name calculation`
  String get historyNameCalculation {
    return Intl.message(
      'Name calculation',
      name: 'historyNameCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Rename calculation`
  String get historyRenameCalculation {
    return Intl.message(
      'Rename calculation',
      name: 'historyRenameCalculation',
      desc: '',
      args: [],
    );
  }

  /// `Calculation name`
  String get historyCalculationName {
    return Intl.message(
      'Calculation name',
      name: 'historyCalculationName',
      desc: '',
      args: [],
    );
  }

  /// `Pinned`
  String get historyPinned {
    return Intl.message('Pinned', name: 'historyPinned', desc: '', args: []);
  }

  /// `You can pin up to 25 calculations.`
  String get historyPinLimit {
    return Intl.message(
      'You can pin up to 25 calculations.',
      name: 'historyPinLimit',
      desc: '',
      args: [],
    );
  }

  /// `Use a shorter name.`
  String get historyNameTooLong {
    return Intl.message(
      'Use a shorter name.',
      name: 'historyNameTooLong',
      desc: '',
      args: [],
    );
  }

  /// `Everyday tools`
  String get everydayTools {
    return Intl.message(
      'Everyday tools',
      name: 'everydayTools',
      desc: '',
      args: [],
    );
  }

  /// `Tip and bill splitter`
  String get everydayTipSplitter {
    return Intl.message(
      'Tip and bill splitter',
      name: 'everydayTipSplitter',
      desc: '',
      args: [],
    );
  }

  /// `Unit price comparison`
  String get everydayUnitPrice {
    return Intl.message(
      'Unit price comparison',
      name: 'everydayUnitPrice',
      desc: '',
      args: [],
    );
  }

  /// `Bill amount`
  String get everydayBill {
    return Intl.message(
      'Bill amount',
      name: 'everydayBill',
      desc: '',
      args: [],
    );
  }

  /// `Tip (%)`
  String get everydayTipPercent {
    return Intl.message(
      'Tip (%)',
      name: 'everydayTipPercent',
      desc: '',
      args: [],
    );
  }

  /// `Number of people`
  String get everydayPeople {
    return Intl.message(
      'Number of people',
      name: 'everydayPeople',
      desc: '',
      args: [],
    );
  }

  /// `Tip amount`
  String get everydayTipAmount {
    return Intl.message(
      'Tip amount',
      name: 'everydayTipAmount',
      desc: '',
      args: [],
    );
  }

  /// `Total with tip`
  String get everydayBillTotal {
    return Intl.message(
      'Total with tip',
      name: 'everydayBillTotal',
      desc: '',
      args: [],
    );
  }

  /// `Per person`
  String get everydayPerPerson {
    return Intl.message(
      'Per person',
      name: 'everydayPerPerson',
      desc: '',
      args: [],
    );
  }

  /// `1 person pays {amount}`
  String everydayOnePersonPays(String amount) {
    return Intl.message(
      '1 person pays $amount',
      name: 'everydayOnePersonPays',
      desc: '',
      args: [amount],
    );
  }

  /// `{people} people pay {amount}`
  String everydayPeoplePay(String people, String amount) {
    return Intl.message(
      '$people people pay $amount',
      name: 'everydayPeoplePay',
      desc: '',
      args: [people, amount],
    );
  }

  /// `Enter a non-negative amount with up to two decimal places.`
  String get everydayMoneyError {
    return Intl.message(
      'Enter a non-negative amount with up to two decimal places.',
      name: 'everydayMoneyError',
      desc: '',
      args: [],
    );
  }

  /// `Enter a non-negative number.`
  String get everydayNonnegativeError {
    return Intl.message(
      'Enter a non-negative number.',
      name: 'everydayNonnegativeError',
      desc: '',
      args: [],
    );
  }

  /// `Enter a positive whole number.`
  String get everydayCountError {
    return Intl.message(
      'Enter a positive whole number.',
      name: 'everydayCountError',
      desc: '',
      args: [],
    );
  }

  /// `Enter a size greater than zero.`
  String get everydaySizeError {
    return Intl.message(
      'Enter a size greater than zero.',
      name: 'everydaySizeError',
      desc: '',
      args: [],
    );
  }

  /// `Count`
  String get everydayCount {
    return Intl.message('Count', name: 'everydayCount', desc: '', args: []);
  }

  /// `Item A`
  String get everydayItemA {
    return Intl.message('Item A', name: 'everydayItemA', desc: '', args: []);
  }

  /// `Item B`
  String get everydayItemB {
    return Intl.message('Item B', name: 'everydayItemB', desc: '', args: []);
  }

  /// `Price`
  String get everydayPrice {
    return Intl.message('Price', name: 'everydayPrice', desc: '', args: []);
  }

  /// `Package size`
  String get everydayPackageSize {
    return Intl.message(
      'Package size',
      name: 'everydayPackageSize',
      desc: '',
      args: [],
    );
  }

  /// `item`
  String get everydayEach {
    return Intl.message('item', name: 'everydayEach', desc: '', args: []);
  }

  /// `{price} per {unit}`
  String everydayUnitCost(String price, String unit) {
    return Intl.message(
      '$price per $unit',
      name: 'everydayUnitCost',
      desc: '',
      args: [price, unit],
    );
  }

  /// `Item A costs less per unit.`
  String get everydayItemACheaper {
    return Intl.message(
      'Item A costs less per unit.',
      name: 'everydayItemACheaper',
      desc: '',
      args: [],
    );
  }

  /// `Item B costs less per unit.`
  String get everydayItemBCheaper {
    return Intl.message(
      'Item B costs less per unit.',
      name: 'everydayItemBCheaper',
      desc: '',
      args: [],
    );
  }

  /// `Both items have the same unit price.`
  String get everydayEqualPrice {
    return Intl.message(
      'Both items have the same unit price.',
      name: 'everydayEqualPrice',
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
