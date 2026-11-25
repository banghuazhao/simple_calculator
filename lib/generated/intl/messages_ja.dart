// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(date) => "レート更新日: ${date}";

  static String m1(item) => "${item} が最もお得です。";

  static String m2(letter) => "商品 ${letter}";

  static String m3(amount) => "1人が ${amount} 支払い";

  static String m4(people, amount) => "${people}人が ${amount} 支払い";

  static String m5(percent, savings, unit) =>
      "${percent}% お得（${unit} あたり ${savings} 節約）";

  static String m6(price, unit) => "${unit} あたり ${price}";

  static String m7(alternate, baseline) => "差分（${alternate} − ${baseline}）";

  static String m8(count, total) => "合計 (${count}件): ${total}";

  static String m9(message, position) => "${message}（${position}文字目）";

  static String m10(name) => "関数 ${name} は不明です。";

  static String m11(name) => "${name} を数値または Ans に置き換えてください。";

  static String m12(value) => "表示値を使用 (${value})";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "Classic_15_Puzzle": MessageLookupByLibrary.simpleMessage(
      "Classic 15 Puzzle",
    ),
    "Classic_2048": MessageLookupByLibrary.simpleMessage("Classic 2048"),
    "Classic_Memory_Game": MessageLookupByLibrary.simpleMessage(
      "Classic Memory Game",
    ),
    "Classic_Minesweeper": MessageLookupByLibrary.simpleMessage(
      "Classic Minesweeper",
    ),
    "Classic_Reversi": MessageLookupByLibrary.simpleMessage("Classic Reversi"),
    "Classic_Tic_Tac_Toe": MessageLookupByLibrary.simpleMessage(
      "Classic Tic Tac Toe",
    ),
    "Crazy_Pyramid": MessageLookupByLibrary.simpleMessage("Crazy Pyramid"),
    "Easy_Unit": MessageLookupByLibrary.simpleMessage("Easy Unit"),
    "Falling_Block_Puzzle": MessageLookupByLibrary.simpleMessage(
      "Falling Block Puzzle",
    ),
    "Flappy_Fish": MessageLookupByLibrary.simpleMessage("Flappy Fish"),
    "Fling_Knife": MessageLookupByLibrary.simpleMessage("Fling Knife"),
    "Garden_Catch_Bugs": MessageLookupByLibrary.simpleMessage(
      "Garden: Catch Bugs",
    ),
    "How_to_change_level": MessageLookupByLibrary.simpleMessage("レベルを変更するには？"),
    "How_to_change_level_explain": MessageLookupByLibrary.simpleMessage(
      "ゲーム開始前またはリセット後に左右のボタンをタップしてレベルを変更できます。",
    ),
    "Image_Guru": MessageLookupByLibrary.simpleMessage("Image Guru"),
    "Instant_Face": MessageLookupByLibrary.simpleMessage("Instant Face"),
    "Minesweeper_Go": MessageLookupByLibrary.simpleMessage("Minesweeper Go"),
    "More": MessageLookupByLibrary.simpleMessage("その他"),
    "MoreApps": MessageLookupByLibrary.simpleMessage("その他のアプリ"),
    "Onlynote": MessageLookupByLibrary.simpleMessage("Onlynote"),
    "Relaxing_Up": MessageLookupByLibrary.simpleMessage("Relaxing Up"),
    "Saving_Ambulance": MessageLookupByLibrary.simpleMessage(
      "Saving Ambulance",
    ),
    "Shows": MessageLookupByLibrary.simpleMessage("Shows"),
    "Simple_Calculator": MessageLookupByLibrary.simpleMessage("シンプル電卓"),
    "Simple_English_Dictionary": MessageLookupByLibrary.simpleMessage(
      "Simple English Dictionary",
    ),
    "Solitaire_Guru": MessageLookupByLibrary.simpleMessage("Solitaire Guru"),
    "Space_Jumper": MessageLookupByLibrary.simpleMessage("Space Jumper"),
    "Sudoku_Lovers": MessageLookupByLibrary.simpleMessage("Sudoku Lovers"),
    "TripMark": MessageLookupByLibrary.simpleMessage("TripMark"),
    "We_Play_Piano": MessageLookupByLibrary.simpleMessage("We Play Piano"),
    "World_Weather_Live": MessageLookupByLibrary.simpleMessage(
      "World Weather Live",
    ),
    "Yes_Habit": MessageLookupByLibrary.simpleMessage("Yes Habit"),
    "add": MessageLookupByLibrary.simpleMessage("足す"),
    "allClear": MessageLookupByLibrary.simpleMessage("オールクリア"),
    "alwaysOnTop": MessageLookupByLibrary.simpleMessage("ウィンドウを常に手前に表示"),
    "alwaysOnTopDescription": MessageLookupByLibrary.simpleMessage(
      "macOS で SwiftSum を他のウィンドウより前面に固定します",
    ),
    "background_music": MessageLookupByLibrary.simpleMessage("BGM"),
    "backspace": MessageLookupByLibrary.simpleMessage("1文字削除"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("バックアップと復元"),
    "backupCopied": MessageLookupByLibrary.simpleMessage(
      "バックアップ JSON をクリップボードにコピーしました。",
    ),
    "backupExport": MessageLookupByLibrary.simpleMessage("バックアップをエクスポート"),
    "backupExportDescription": MessageLookupByLibrary.simpleMessage(
      "履歴・数式・テーマ・設定を JSON としてコピー",
    ),
    "backupImport": MessageLookupByLibrary.simpleMessage("バックアップをインポート"),
    "backupImportAction": MessageLookupByLibrary.simpleMessage("復元"),
    "backupImportDescription": MessageLookupByLibrary.simpleMessage(
      "JSON バックアップから保存データを復元",
    ),
    "backupImportFailed": MessageLookupByLibrary.simpleMessage(
      "無効なバックアップ JSON です。変更は行われませんでした。",
    ),
    "backupImportSuccess": MessageLookupByLibrary.simpleMessage(
      "バックアップを復元しました。",
    ),
    "backupPasteHint": MessageLookupByLibrary.simpleMessage(
      "SwiftSum の JSON バックアップを貼り付け",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "changeSign": MessageLookupByLibrary.simpleMessage("符号を切り替え"),
    "clear": MessageLookupByLibrary.simpleMessage("消去"),
    "clearAllHistory": MessageLookupByLibrary.simpleMessage("すべて消去"),
    "clearEntry": MessageLookupByLibrary.simpleMessage("入力クリア"),
    "clearHistoryMessage": MessageLookupByLibrary.simpleMessage(
      "保存されているすべての計算履歴が削除されます。",
    ),
    "clearHistoryTitle": MessageLookupByLibrary.simpleMessage("履歴を消去しますか？"),
    "clearInput": MessageLookupByLibrary.simpleMessage("入力をクリア"),
    "clearSearch": MessageLookupByLibrary.simpleMessage("検索をクリア"),
    "clipboardUnavailable": MessageLookupByLibrary.simpleMessage(
      "クリップボードを利用できません。もう一度お試しください。",
    ),
    "commaDecimal": MessageLookupByLibrary.simpleMessage("カンマ小数点"),
    "commaDecimalDescription": MessageLookupByLibrary.simpleMessage(
      "1.234,56 のように小数点にカンマを使用します",
    ),
    "converterAcre": MessageLookupByLibrary.simpleMessage("エーカー"),
    "converterAllUnits": MessageLookupByLibrary.simpleMessage("すべての単位"),
    "converterAmount": MessageLookupByLibrary.simpleMessage("値"),
    "converterArea": MessageLookupByLibrary.simpleMessage("面積"),
    "converterByte": MessageLookupByLibrary.simpleMessage("バイト"),
    "converterCelsius": MessageLookupByLibrary.simpleMessage("摂氏 (°C)"),
    "converterCentimeter": MessageLookupByLibrary.simpleMessage("センチメートル"),
    "converterData": MessageLookupByLibrary.simpleMessage("データ量"),
    "converterDay": MessageLookupByLibrary.simpleMessage("日"),
    "converterFahrenheit": MessageLookupByLibrary.simpleMessage("華氏 (°F)"),
    "converterFoot": MessageLookupByLibrary.simpleMessage("フィート"),
    "converterFrom": MessageLookupByLibrary.simpleMessage("変換元"),
    "converterGigabyte": MessageLookupByLibrary.simpleMessage("ギガバイト"),
    "converterGram": MessageLookupByLibrary.simpleMessage("グラム"),
    "converterHectare": MessageLookupByLibrary.simpleMessage("ヘクタール"),
    "converterHour": MessageLookupByLibrary.simpleMessage("時間"),
    "converterInch": MessageLookupByLibrary.simpleMessage("インチ"),
    "converterKelvin": MessageLookupByLibrary.simpleMessage("ケルビン (K)"),
    "converterKilobyte": MessageLookupByLibrary.simpleMessage("キロバイト"),
    "converterKilogram": MessageLookupByLibrary.simpleMessage("キログラム"),
    "converterKilometer": MessageLookupByLibrary.simpleMessage("キロメートル"),
    "converterKmPerHour": MessageLookupByLibrary.simpleMessage("時速 (km/h)"),
    "converterKnot": MessageLookupByLibrary.simpleMessage("ノット"),
    "converterLength": MessageLookupByLibrary.simpleMessage("長さ"),
    "converterLiter": MessageLookupByLibrary.simpleMessage("リットル"),
    "converterMass": MessageLookupByLibrary.simpleMessage("質量"),
    "converterMegabyte": MessageLookupByLibrary.simpleMessage("メガバイト"),
    "converterMeter": MessageLookupByLibrary.simpleMessage("メートル"),
    "converterMetersPerSecond": MessageLookupByLibrary.simpleMessage(
      "秒速 (m/s)",
    ),
    "converterMile": MessageLookupByLibrary.simpleMessage("マイル"),
    "converterMilesPerHour": MessageLookupByLibrary.simpleMessage("時速 (mph)"),
    "converterMilligram": MessageLookupByLibrary.simpleMessage("ミリグラム"),
    "converterMilliliter": MessageLookupByLibrary.simpleMessage("ミリリットル"),
    "converterMillimeter": MessageLookupByLibrary.simpleMessage("ミリメートル"),
    "converterMinute": MessageLookupByLibrary.simpleMessage("分"),
    "converterOunce": MessageLookupByLibrary.simpleMessage("オンス"),
    "converterPinPair": MessageLookupByLibrary.simpleMessage("単位ペアをピン留め"),
    "converterPinnedPairs": MessageLookupByLibrary.simpleMessage("クイックプリセット"),
    "converterPound": MessageLookupByLibrary.simpleMessage("ポンド"),
    "converterSecond": MessageLookupByLibrary.simpleMessage("秒"),
    "converterSpeed": MessageLookupByLibrary.simpleMessage("速度"),
    "converterSquareCentimeter": MessageLookupByLibrary.simpleMessage(
      "平方センチメートル",
    ),
    "converterSquareFoot": MessageLookupByLibrary.simpleMessage("平方フィート"),
    "converterSquareInch": MessageLookupByLibrary.simpleMessage("平方インチ"),
    "converterSquareKilometer": MessageLookupByLibrary.simpleMessage(
      "平方キロメートル",
    ),
    "converterSquareMeter": MessageLookupByLibrary.simpleMessage("平方メートル"),
    "converterSquareMile": MessageLookupByLibrary.simpleMessage("平方マイル"),
    "converterSwap": MessageLookupByLibrary.simpleMessage("単位を入れ替え"),
    "converterTablespoon": MessageLookupByLibrary.simpleMessage("大さじ"),
    "converterTeaspoon": MessageLookupByLibrary.simpleMessage("小さじ"),
    "converterTemperature": MessageLookupByLibrary.simpleMessage("温度"),
    "converterTerabyte": MessageLookupByLibrary.simpleMessage("テラバイト"),
    "converterTime": MessageLookupByLibrary.simpleMessage("時間"),
    "converterTo": MessageLookupByLibrary.simpleMessage("変換先"),
    "converterTonne": MessageLookupByLibrary.simpleMessage("メートルトン"),
    "converterUkFluidOunce": MessageLookupByLibrary.simpleMessage("英液量オンス"),
    "converterUkGallon": MessageLookupByLibrary.simpleMessage("英ガロン"),
    "converterUnpinPair": MessageLookupByLibrary.simpleMessage("ピン留めを解除"),
    "converterUsCup": MessageLookupByLibrary.simpleMessage("米カップ"),
    "converterUsFluidOunce": MessageLookupByLibrary.simpleMessage("米液量オンス"),
    "converterUsGallon": MessageLookupByLibrary.simpleMessage("米ガロン"),
    "converterVolume": MessageLookupByLibrary.simpleMessage("体積"),
    "converterWeek": MessageLookupByLibrary.simpleMessage("週"),
    "converterYard": MessageLookupByLibrary.simpleMessage("ヤード"),
    "copied": MessageLookupByLibrary.simpleMessage("コピーしました"),
    "copyAllHistory": MessageLookupByLibrary.simpleMessage("すべての履歴をコピー"),
    "copyCalculation": MessageLookupByLibrary.simpleMessage("計算式をコピー"),
    "copyMatchingHistory": MessageLookupByLibrary.simpleMessage("一致する計算をコピー"),
    "copyResult": MessageLookupByLibrary.simpleMessage("結果をコピー"),
    "copySummary": MessageLookupByLibrary.simpleMessage("要約をコピー"),
    "currencyConverter": MessageLookupByLibrary.simpleMessage("通貨換算"),
    "currencyCustomRate": MessageLookupByLibrary.simpleMessage("カスタムレート"),
    "currencyCustomRateActive": MessageLookupByLibrary.simpleMessage(
      "カスタムレート使用中",
    ),
    "currencyOfflineRates": MessageLookupByLibrary.simpleMessage("オフライン参考レート"),
    "currencyRate": MessageLookupByLibrary.simpleMessage("為替レート"),
    "currencyRefreshFailed": MessageLookupByLibrary.simpleMessage(
      "レートを更新できませんでした。保存済みのレートを使用します。",
    ),
    "currencyRefreshRates": MessageLookupByLibrary.simpleMessage("レートを更新"),
    "currencyRefreshSuccess": MessageLookupByLibrary.simpleMessage(
      "為替レートを更新しました。",
    ),
    "currencyResetRate": MessageLookupByLibrary.simpleMessage("レートをリセット"),
    "currencyUpdatedAt": m0,
    "customTheme": MessageLookupByLibrary.simpleMessage("カスタムテーマ"),
    "customThemeApply": MessageLookupByLibrary.simpleMessage("カスタムテーマを適用"),
    "customThemeBackground": MessageLookupByLibrary.simpleMessage("背景"),
    "customThemeContrastGood": MessageLookupByLibrary.simpleMessage(
      "コントラスト確認: WCAG AA 適合",
    ),
    "customThemeDescription": MessageLookupByLibrary.simpleMessage(
      "コントラスト確認付きで独自の配色を作成",
    ),
    "customThemeFunctionKeys": MessageLookupByLibrary.simpleMessage("機能キー"),
    "customThemeNumberKeys": MessageLookupByLibrary.simpleMessage("数字キー"),
    "customThemeOperatorKeys": MessageLookupByLibrary.simpleMessage("演算キー"),
    "darkTheme": MessageLookupByLibrary.simpleMessage("ダークテーマ"),
    "decimalPoint": MessageLookupByLibrary.simpleMessage("小数点"),
    "decreasePeople": MessageLookupByLibrary.simpleMessage("人数を減らす"),
    "deleteCalculation": MessageLookupByLibrary.simpleMessage("計算を削除"),
    "divide": MessageLookupByLibrary.simpleMessage("割る"),
    "editFirstOperand": MessageLookupByLibrary.simpleMessage("1つ目の数値を編集"),
    "editSecondOperand": MessageLookupByLibrary.simpleMessage("2つ目の数値を編集"),
    "equals": MessageLookupByLibrary.simpleMessage("イコール"),
    "error": MessageLookupByLibrary.simpleMessage("エラー"),
    "everydayAbsoluteChange": MessageLookupByLibrary.simpleMessage("差額"),
    "everydayAddItem": MessageLookupByLibrary.simpleMessage("商品を追加"),
    "everydayAnnualRate": MessageLookupByLibrary.simpleMessage("年利 (%)"),
    "everydayBestValue": m1,
    "everydayBill": MessageLookupByLibrary.simpleMessage("お会計金額"),
    "everydayBillTotal": MessageLookupByLibrary.simpleMessage("チップ込み合計"),
    "everydayBusinessDays": MessageLookupByLibrary.simpleMessage("営業日（月〜金）"),
    "everydayCompoundMonthly": MessageLookupByLibrary.simpleMessage("毎月"),
    "everydayCompoundQuarterly": MessageLookupByLibrary.simpleMessage("四半期ごと"),
    "everydayCompoundTab": MessageLookupByLibrary.simpleMessage("複利"),
    "everydayCompoundYearly": MessageLookupByLibrary.simpleMessage("毎年"),
    "everydayCompoundingFrequency": MessageLookupByLibrary.simpleMessage(
      "複利頻度",
    ),
    "everydayCost": MessageLookupByLibrary.simpleMessage("原価"),
    "everydayCount": MessageLookupByLibrary.simpleMessage("個数"),
    "everydayCountError": MessageLookupByLibrary.simpleMessage(
      "正の整数を入力してください。",
    ),
    "everydayDateAddTab": MessageLookupByLibrary.simpleMessage("日数の加減"),
    "everydayDateCalculator": MessageLookupByLibrary.simpleMessage("日付計算"),
    "everydayDateDifferenceTab": MessageLookupByLibrary.simpleMessage("日数差"),
    "everydayDaysOffset": MessageLookupByLibrary.simpleMessage("日数（負数で減算）"),
    "everydayDiscountPercent": MessageLookupByLibrary.simpleMessage("割引 (%)"),
    "everydayDiscountTax": MessageLookupByLibrary.simpleMessage("割引・消費税"),
    "everydayEach": MessageLookupByLibrary.simpleMessage("個"),
    "everydayEndDate": MessageLookupByLibrary.simpleMessage("終了日"),
    "everydayEqualPrice": MessageLookupByLibrary.simpleMessage("両商品の単価は同じです。"),
    "everydayExtraDiscountPercent": MessageLookupByLibrary.simpleMessage(
      "追加割引 (%)",
    ),
    "everydayFinalBalance": MessageLookupByLibrary.simpleMessage("最終残高"),
    "everydayFinalPrice": MessageLookupByLibrary.simpleMessage("最終価格"),
    "everydayFromValue": MessageLookupByLibrary.simpleMessage("変更前の値"),
    "everydayInterestEarned": MessageLookupByLibrary.simpleMessage("運用益"),
    "everydayItemA": MessageLookupByLibrary.simpleMessage("商品 A"),
    "everydayItemACheaper": MessageLookupByLibrary.simpleMessage(
      "商品 A の方が単価が安いです。",
    ),
    "everydayItemB": MessageLookupByLibrary.simpleMessage("商品 B"),
    "everydayItemBCheaper": MessageLookupByLibrary.simpleMessage(
      "商品 B の方が単価が安いです。",
    ),
    "everydayItemLabel": m2,
    "everydayLoanCompound": MessageLookupByLibrary.simpleMessage("ローン・複利"),
    "everydayLoanTab": MessageLookupByLibrary.simpleMessage("ローン"),
    "everydayMargin": MessageLookupByLibrary.simpleMessage("利益率"),
    "everydayMarginTab": MessageLookupByLibrary.simpleMessage("利益率"),
    "everydayMarkup": MessageLookupByLibrary.simpleMessage("値入率"),
    "everydayMoneyError": MessageLookupByLibrary.simpleMessage(
      "小数第2位までの0以上の金額を入力してください。",
    ),
    "everydayMonthlyContribution": MessageLookupByLibrary.simpleMessage(
      "毎月の積立額",
    ),
    "everydayMonthlyPayment": MessageLookupByLibrary.simpleMessage("毎月の返済額"),
    "everydayNonnegativeError": MessageLookupByLibrary.simpleMessage(
      "0以上の数値を入力してください。",
    ),
    "everydayOnePersonPays": m3,
    "everydayOriginalPrice": MessageLookupByLibrary.simpleMessage("元の価格"),
    "everydayPackCount": MessageLookupByLibrary.simpleMessage("パック数"),
    "everydayPackageSize": MessageLookupByLibrary.simpleMessage("内容量"),
    "everydayPeople": MessageLookupByLibrary.simpleMessage("人数"),
    "everydayPeoplePay": m4,
    "everydayPerPerson": MessageLookupByLibrary.simpleMessage("1人あたり"),
    "everydayPercentChange": MessageLookupByLibrary.simpleMessage("増減率"),
    "everydayPercentChangeTab": MessageLookupByLibrary.simpleMessage("増減率"),
    "everydayPercentTools": MessageLookupByLibrary.simpleMessage("増減率・利益率"),
    "everydayPrice": MessageLookupByLibrary.simpleMessage("価格"),
    "everydayPrincipal": MessageLookupByLibrary.simpleMessage("借入金額"),
    "everydayProfit": MessageLookupByLibrary.simpleMessage("利益"),
    "everydayRemoveItem": MessageLookupByLibrary.simpleMessage("商品を削除"),
    "everydayResultDate": MessageLookupByLibrary.simpleMessage("計算後の日付"),
    "everydaySavesPercent": m5,
    "everydaySellingPrice": MessageLookupByLibrary.simpleMessage("売価"),
    "everydaySizeError": MessageLookupByLibrary.simpleMessage(
      "0より大きい値を入力してください。",
    ),
    "everydayStartDate": MessageLookupByLibrary.simpleMessage("開始日"),
    "everydayStartingBalance": MessageLookupByLibrary.simpleMessage("初期元本"),
    "everydayTaxAmount": MessageLookupByLibrary.simpleMessage("税額"),
    "everydayTaxPercent": MessageLookupByLibrary.simpleMessage("税率 (%)"),
    "everydayTermYears": MessageLookupByLibrary.simpleMessage("期間（年）"),
    "everydayTipAmount": MessageLookupByLibrary.simpleMessage("チップ額"),
    "everydayTipPercent": MessageLookupByLibrary.simpleMessage("チップ (%)"),
    "everydayTipSplitter": MessageLookupByLibrary.simpleMessage("チップ・割り勘"),
    "everydayToValue": MessageLookupByLibrary.simpleMessage("変更後の値"),
    "everydayTools": MessageLookupByLibrary.simpleMessage("日常ツール"),
    "everydayTotalContributions": MessageLookupByLibrary.simpleMessage(
      "積立元本合計",
    ),
    "everydayTotalDays": MessageLookupByLibrary.simpleMessage("合計日数"),
    "everydayTotalInterest": MessageLookupByLibrary.simpleMessage("総利息"),
    "everydayTotalPayment": MessageLookupByLibrary.simpleMessage("総返済額"),
    "everydayUnitCost": m6,
    "everydayUnitPrice": MessageLookupByLibrary.simpleMessage("単価比較"),
    "everydayWeeksAndDays": MessageLookupByLibrary.simpleMessage("週と日"),
    "everydayYouSave": MessageLookupByLibrary.simpleMessage("割引額"),
    "followSystemTheme": MessageLookupByLibrary.simpleMessage("システム外観に合わせる"),
    "followSystemThemeDescription": MessageLookupByLibrary.simpleMessage(
      "ライト／ダークテーマをシステム設定に応じて自動で切り替えます",
    ),
    "formulaAlternate": MessageLookupByLibrary.simpleMessage("比較案"),
    "formulaAlternateName": MessageLookupByLibrary.simpleMessage("比較シナリオ名"),
    "formulaBaseline": MessageLookupByLibrary.simpleMessage("基準"),
    "formulaBaselineName": MessageLookupByLibrary.simpleMessage("基準シナリオ名"),
    "formulaCopyComparison": MessageLookupByLibrary.simpleMessage("比較をコピー"),
    "formulaCustomize": MessageLookupByLibrary.simpleMessage("ラベルとシナリオをカスタマイズ"),
    "formulaDelete": MessageLookupByLibrary.simpleMessage("数式を削除"),
    "formulaDeleteMessage": MessageLookupByLibrary.simpleMessage(
      "この保存済み数式を削除しますか？",
    ),
    "formulaDifference": MessageLookupByLibrary.simpleMessage("差分（比較案 − 基準）"),
    "formulaDuplicate": MessageLookupByLibrary.simpleMessage("数式を複製"),
    "formulaEdit": MessageLookupByLibrary.simpleMessage("数式を編集"),
    "formulaEmpty": MessageLookupByLibrary.simpleMessage("保存された数式はまだありません。"),
    "formulaExampleBmi": MessageLookupByLibrary.simpleMessage("BMI"),
    "formulaExampleCompound": MessageLookupByLibrary.simpleMessage("複利計算"),
    "formulaExampleDiscount": MessageLookupByLibrary.simpleMessage("割引後価格"),
    "formulaExampleFuel": MessageLookupByLibrary.simpleMessage("燃料費"),
    "formulaExampleLoan": MessageLookupByLibrary.simpleMessage("月々のローン返済"),
    "formulaExampleMargin": MessageLookupByLibrary.simpleMessage("利益率 (%)"),
    "formulaExampleOrderTotal": MessageLookupByLibrary.simpleMessage("注文合計"),
    "formulaExampleTax": MessageLookupByLibrary.simpleMessage("税込価格"),
    "formulaExamples": MessageLookupByLibrary.simpleMessage("数式の例"),
    "formulaExpression": MessageLookupByLibrary.simpleMessage("数式"),
    "formulaExpressionHint": MessageLookupByLibrary.simpleMessage(
      "例: price * quantity",
    ),
    "formulaInputLabel": MessageLookupByLibrary.simpleMessage("入力ラベル"),
    "formulaInputUnit": MessageLookupByLibrary.simpleMessage("単位"),
    "formulaInvalidExpression": MessageLookupByLibrary.simpleMessage(
      "有効な数式を入力してください。",
    ),
    "formulaInvalidInput": MessageLookupByLibrary.simpleMessage(
      "有効な数値を入力してください。",
    ),
    "formulaInvalidName": MessageLookupByLibrary.simpleMessage("数式名を入力してください。"),
    "formulaLimitReached": MessageLookupByLibrary.simpleMessage(
      "最大30件の数式を保存できます。",
    ),
    "formulaMoveDown": MessageLookupByLibrary.simpleMessage("下へ移動"),
    "formulaMoveUp": MessageLookupByLibrary.simpleMessage("上へ移動"),
    "formulaName": MessageLookupByLibrary.simpleMessage("数式名"),
    "formulaNamedDifference": m7,
    "formulaNew": MessageLookupByLibrary.simpleMessage("新しい数式"),
    "formulaNoResult": MessageLookupByLibrary.simpleMessage("結果なし"),
    "formulaSave": MessageLookupByLibrary.simpleMessage("保存"),
    "formulaSaveFailed": MessageLookupByLibrary.simpleMessage("数式を保存できませんでした。"),
    "formulaSearch": MessageLookupByLibrary.simpleMessage("数式を検索"),
    "formulaTooManyInputs": MessageLookupByLibrary.simpleMessage(
      "名前付き変数は最大12個までです。",
    ),
    "graphExpressionHelp": MessageLookupByLibrary.simpleMessage(
      "x の関数を入力してください（例: x^2 − 4）。",
    ),
    "graphFindIntersection": MessageLookupByLibrary.simpleMessage("交点"),
    "graphFindRoot": MessageLookupByLibrary.simpleMessage("解を探す"),
    "graphIntersectionNotFound": MessageLookupByLibrary.simpleMessage(
      "この区間に交点が見つかりませんでした。",
    ),
    "graphIntersectionResult": MessageLookupByLibrary.simpleMessage("近似交点"),
    "graphInvalidRange": MessageLookupByLibrary.simpleMessage(
      "最小値が最大値より小さい有限区間を入力してください。",
    ),
    "graphInvalidVariables": MessageLookupByLibrary.simpleMessage(
      "変数には x と前回の答え (Ans) を使用できます。",
    ),
    "graphKeyPoints": MessageLookupByLibrary.simpleMessage("主要ポイント"),
    "graphMaximum": MessageLookupByLibrary.simpleMessage("最大値"),
    "graphMinimum": MessageLookupByLibrary.simpleMessage("最小値"),
    "graphNoValues": MessageLookupByLibrary.simpleMessage("この区間に関数の有限値がありません。"),
    "graphPlot": MessageLookupByLibrary.simpleMessage("描画"),
    "graphPlotHint": MessageLookupByLibrary.simpleMessage(
      "曲線をタップまたはドラッグして値を確認できます。",
    ),
    "graphResetView": MessageLookupByLibrary.simpleMessage("表示をリセット"),
    "graphRootNeedsBracket": MessageLookupByLibrary.simpleMessage(
      "両端で符号が異なる区間、または端点に解がある区間を選んでください。",
    ),
    "graphRootNotFound": MessageLookupByLibrary.simpleMessage(
      "解を確認できませんでした。連続な狭い区間を試してください。",
    ),
    "graphRootResult": MessageLookupByLibrary.simpleMessage("近似解"),
    "graphSecondFunction": MessageLookupByLibrary.simpleMessage(
      "第2関数 g(x)（任意）",
    ),
    "graphUndefined": MessageLookupByLibrary.simpleMessage("未定義"),
    "graphValueTable": MessageLookupByLibrary.simpleMessage("値テーブル"),
    "graphXMax": MessageLookupByLibrary.simpleMessage("x 最大値"),
    "graphXMin": MessageLookupByLibrary.simpleMessage("x 最小値"),
    "graphYIntercept": MessageLookupByLibrary.simpleMessage("y切片"),
    "graphZoomIn": MessageLookupByLibrary.simpleMessage("拡大"),
    "graphZoomOut": MessageLookupByLibrary.simpleMessage("縮小"),
    "hapticFeedback": MessageLookupByLibrary.simpleMessage("触覚フィードバック"),
    "hapticFeedbackDescription": MessageLookupByLibrary.simpleMessage(
      "電卓のキー操作時に振動します",
    ),
    "helpAndShortcuts": MessageLookupByLibrary.simpleMessage("ヒントとショートカット"),
    "helpBasics": MessageLookupByLibrary.simpleMessage("電卓の使い方"),
    "helpConverter": MessageLookupByLibrary.simpleMessage(
      "日常ツールから単位換算を開き、値を入力して電卓へ送れます。",
    ),
    "helpCopy": MessageLookupByLibrary.simpleMessage(
      "結果をタップすると数値をコピーできます。= を押した後は式の横のコピーボタンで計算式全体をコピーできます。",
    ),
    "helpCopyHistory": MessageLookupByLibrary.simpleMessage(
      "すべての履歴をコピー、または一致する計算をプレーンテキストでコピーできます。表計算ソフトに貼り付ける場合は TSV 形式でコピーしてください。",
    ),
    "helpEditOperands": MessageLookupByLibrary.simpleMessage(
      "メイン表示の上にある数値をタップすると修正できます。完了した式の横のボタンで式全体をコピーできます。",
    ),
    "helpEverydayTools": MessageLookupByLibrary.simpleMessage(
      "ツールバーから日常ツールを開くと、割り勘、単価比較、単位換算などを利用できます。",
    ),
    "helpHistory": MessageLookupByLibrary.simpleMessage(
      "履歴は最大100件保存されます。項目をタップして結果を再利用するか、メニューから計算を編集できます。スワイプで削除し、元に戻すで復元できます。",
    ),
    "helpKeyboard": MessageLookupByLibrary.simpleMessage("キーボードショートカット"),
    "helpPaste": MessageLookupByLibrary.simpleMessage(
      "3桁区切りや指数表記を含む単一の有限数値を貼り付けできます。式やその他のテキストは受け付けません。",
    ),
    "helpPercent": MessageLookupByLibrary.simpleMessage(
      "+ や − と % を組み合わせて増減を計算できます。例: 200 + 10% = 220",
    ),
    "helpPremiumFormulas": MessageLookupByLibrary.simpleMessage(
      "保存した数式を開いてシナリオを比較できます。数式を編集してラベルや単位、シナリオ名を変更できます。",
    ),
    "helpPremiumScientific": MessageLookupByLibrary.simpleMessage(
      "三角関数を使う前に、関数電卓で度（DEG）またはラジアン（RAD）を選択してください。",
    ),
    "helpPremiumShortcut": MessageLookupByLibrary.simpleMessage(
      "ツールバーのプレミアムツールをタップして、関数電卓や再利用可能な数式を開けます。",
    ),
    "helpScientificAdvanced": MessageLookupByLibrary.simpleMessage(
      "Ans で前回の結果、EXP で指数、ENG で工学表記を使えます。グラフでは描画・値テーブル・解の探索ができます。",
    ),
    "helpUndo": MessageLookupByLibrary.simpleMessage(
      "元に戻すで直前の入力を復元できます。シェイク操作と振動は入力設定で変更できます。",
    ),
    "highContrast": MessageLookupByLibrary.simpleMessage("ハイコントラスト"),
    "highContrastDescription": MessageLookupByLibrary.simpleMessage(
      "選択中のテーマを保ったまま、数字とボタンの視認性を高めます。",
    ),
    "history": MessageLookupByLibrary.simpleMessage("履歴"),
    "historyCalculationName": MessageLookupByLibrary.simpleMessage("計算名"),
    "historyCopyAsTsv": MessageLookupByLibrary.simpleMessage("TSV でコピー"),
    "historyDeleted": MessageLookupByLibrary.simpleMessage("計算を削除しました"),
    "historyEarlier": MessageLookupByLibrary.simpleMessage("それ以前"),
    "historyEditCalculation": MessageLookupByLibrary.simpleMessage("計算を編集"),
    "historyEntryActions": MessageLookupByLibrary.simpleMessage("計算の操作"),
    "historyExpressionHelp": MessageLookupByLibrary.simpleMessage(
      "例: (2 + 3) × 4 または 200 + 10%",
    ),
    "historyInvalidExpression": MessageLookupByLibrary.simpleMessage(
      "有効な算術式を入力してください。",
    ),
    "historyNameCalculation": MessageLookupByLibrary.simpleMessage("計算に名前を付ける"),
    "historyNameTooLong": MessageLookupByLibrary.simpleMessage(
      "より短い名前を使用してください。",
    ),
    "historyPinCalculation": MessageLookupByLibrary.simpleMessage("計算をピン留め"),
    "historyPinLimit": MessageLookupByLibrary.simpleMessage("最大25件までピン留めできます。"),
    "historyPinned": MessageLookupByLibrary.simpleMessage("ピン留め"),
    "historyPinnedOnly": MessageLookupByLibrary.simpleMessage("ピン留めのみ"),
    "historyRenameCalculation": MessageLookupByLibrary.simpleMessage("名前を変更"),
    "historyToday": MessageLookupByLibrary.simpleMessage("今日"),
    "historyUnpinCalculation": MessageLookupByLibrary.simpleMessage("ピン留めを解除"),
    "historyUseSum": MessageLookupByLibrary.simpleMessage("合計を使う"),
    "historyVisibleSum": m8,
    "historyYesterday": MessageLookupByLibrary.simpleMessage("昨日"),
    "increasePeople": MessageLookupByLibrary.simpleMessage("人数を増やす"),
    "inputSettings": MessageLookupByLibrary.simpleMessage("入力設定"),
    "invalidPaste": MessageLookupByLibrary.simpleMessage(
      "貼り付ける有効な数値をコピーしてください。",
    ),
    "lightTheme": MessageLookupByLibrary.simpleMessage("ライトテーマ"),
    "memoryAdd": MessageLookupByLibrary.simpleMessage("メモリ加算"),
    "memoryBar": MessageLookupByLibrary.simpleMessage("メモリキー"),
    "memoryBarDescription": MessageLookupByLibrary.simpleMessage(
      "キーパッドの上部に MC・MR・M+・M− を表示します",
    ),
    "memoryClear": MessageLookupByLibrary.simpleMessage("メモリ消去"),
    "memoryRecall": MessageLookupByLibrary.simpleMessage("メモリ呼出"),
    "memorySubtract": MessageLookupByLibrary.simpleMessage("メモリ減算"),
    "multiply": MessageLookupByLibrary.simpleMessage("掛ける"),
    "noCalculationsYet": MessageLookupByLibrary.simpleMessage("計算履歴はまだありません"),
    "noHistoryMatches": MessageLookupByLibrary.simpleMessage("一致する計算がありません"),
    "operandChanged": MessageLookupByLibrary.simpleMessage(
      "計算内容が変更されました。ダイアログを閉じて再度タップしてください。",
    ),
    "pasteNumber": MessageLookupByLibrary.simpleMessage("数値を貼り付け"),
    "pasted": MessageLookupByLibrary.simpleMessage("数値を貼り付けました"),
    "percent": MessageLookupByLibrary.simpleMessage("パーセント"),
    "premium": MessageLookupByLibrary.simpleMessage("SwiftSum プレミアム"),
    "premiumActive": MessageLookupByLibrary.simpleMessage("プレミアムは有効です。"),
    "premiumAdFree": MessageLookupByLibrary.simpleMessage("広告なしの電卓"),
    "premiumBuy": MessageLookupByLibrary.simpleMessage("プレミアムを購入"),
    "premiumCheckPrice": MessageLookupByLibrary.simpleMessage(
      "App Store で価格を確認",
    ),
    "premiumCheckPriceGooglePlay": MessageLookupByLibrary.simpleMessage(
      "Google Play で価格を確認",
    ),
    "premiumFailed": MessageLookupByLibrary.simpleMessage(
      "App Store で処理を完了できませんでした。もう一度お試しください。",
    ),
    "premiumFailedGooglePlay": MessageLookupByLibrary.simpleMessage(
      "Google Play で処理を完了できませんでした。もう一度お試しください。",
    ),
    "premiumNotPurchased": MessageLookupByLibrary.simpleMessage(
      "この Apple アカウントでプレミアム購入が見つかりませんでした。",
    ),
    "premiumNotPurchasedGooglePlay": MessageLookupByLibrary.simpleMessage(
      "この Google アカウントでプレミアム購入が見つかりませんでした。",
    ),
    "premiumOffer": MessageLookupByLibrary.simpleMessage(
      "買い切り購入ですべてのツールを解放し、広告を非表示にします。",
    ),
    "premiumOfferToolsOnly": MessageLookupByLibrary.simpleMessage(
      "買い切り購入で関数電卓と再利用可能な数式を解放します。",
    ),
    "premiumPending": MessageLookupByLibrary.simpleMessage("購入の承認待ちです。"),
    "premiumRestore": MessageLookupByLibrary.simpleMessage("購入を復元"),
    "premiumRestored": MessageLookupByLibrary.simpleMessage("プレミアム購入を復元しました。"),
    "premiumTools": MessageLookupByLibrary.simpleMessage("プレミアムツール"),
    "premiumUnavailable": MessageLookupByLibrary.simpleMessage(
      "プレミアムは現在利用できません。",
    ),
    "premiumWhatIfAlternate": MessageLookupByLibrary.simpleMessage(
      "25% オフなら \$75 です。",
    ),
    "premiumWhatIfBaseline": MessageLookupByLibrary.simpleMessage(
      "10% オフなら \$90 です。",
    ),
    "premiumWhatIfPreview": MessageLookupByLibrary.simpleMessage("シナリオ比較プレビュー"),
    "premiumWhatIfPrice": MessageLookupByLibrary.simpleMessage(
      "元の価格 \$100 から始めます。",
    ),
    "programmerBitwise": MessageLookupByLibrary.simpleMessage("ビット演算"),
    "programmerInputBase": MessageLookupByLibrary.simpleMessage("入力基数"),
    "programmerMode": MessageLookupByLibrary.simpleMessage("プログラマー進数変換"),
    "programmerSecondValue": MessageLookupByLibrary.simpleMessage("2つ目の整数"),
    "programmerValue": MessageLookupByLibrary.simpleMessage("整数値"),
    "redo": MessageLookupByLibrary.simpleMessage("やり直す"),
    "repeatEquals": MessageLookupByLibrary.simpleMessage("イコール繰り返し"),
    "repeatEqualsDescription": MessageLookupByLibrary.simpleMessage(
      "= を再度押すと直前の演算を繰り返します",
    ),
    "reusableFormulas": MessageLookupByLibrary.simpleMessage("再利用可能な数式"),
    "reuseResult": MessageLookupByLibrary.simpleMessage("この結果を使う"),
    "roundUpPerPerson": MessageLookupByLibrary.simpleMessage("1人あたり切り上げ"),
    "scientificArgumentSeparator": MessageLookupByLibrary.simpleMessage(
      "引数区切り",
    ),
    "scientificCalculator": MessageLookupByLibrary.simpleMessage("関数電卓"),
    "scientificCloseParenthesis": MessageLookupByLibrary.simpleMessage("右括弧"),
    "scientificDegrees": MessageLookupByLibrary.simpleMessage("度 (DEG)"),
    "scientificDivideByZero": MessageLookupByLibrary.simpleMessage(
      "0 以外の除数を入力してください。",
    ),
    "scientificDomainError": MessageLookupByLibrary.simpleMessage(
      "この演算で有効な値の範囲を確認してください。",
    ),
    "scientificEngineeringNotation": MessageLookupByLibrary.simpleMessage(
      "工学表記",
    ),
    "scientificErrorPosition": m9,
    "scientificEvaluate": MessageLookupByLibrary.simpleMessage("計算"),
    "scientificExponentEntry": MessageLookupByLibrary.simpleMessage("指数入力"),
    "scientificExpression": MessageLookupByLibrary.simpleMessage("数式"),
    "scientificExpressionHelp": MessageLookupByLibrary.simpleMessage(
      "乗算には * を使います。例: 2 * sin(30) + sqrt(9)",
    ),
    "scientificFactorial": MessageLookupByLibrary.simpleMessage("階乗"),
    "scientificFraction": MessageLookupByLibrary.simpleMessage("分数"),
    "scientificGraph": MessageLookupByLibrary.simpleMessage("グラフ"),
    "scientificHideKeyboard": MessageLookupByLibrary.simpleMessage("キーボードを隠す"),
    "scientificHistory": MessageLookupByLibrary.simpleMessage("関数履歴"),
    "scientificInvalidExpression": MessageLookupByLibrary.simpleMessage(
      "有限の結果になる有効な数式を入力してください。",
    ),
    "scientificMissingParen": MessageLookupByLibrary.simpleMessage(
      "閉じ括弧を追加してください。",
    ),
    "scientificNoAnswer": MessageLookupByLibrary.simpleMessage(
      "Ans を使う前に一度計算してください。",
    ),
    "scientificOpenParenthesis": MessageLookupByLibrary.simpleMessage("左括弧"),
    "scientificOverflow": MessageLookupByLibrary.simpleMessage(
      "結果が対応範囲を超えています。",
    ),
    "scientificPower": MessageLookupByLibrary.simpleMessage("べき乗"),
    "scientificPreview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "scientificPreviousAnswer": MessageLookupByLibrary.simpleMessage("前回の答え"),
    "scientificRadians": MessageLookupByLibrary.simpleMessage("ラジアン (RAD)"),
    "scientificResult": MessageLookupByLibrary.simpleMessage("結果"),
    "scientificShowKeyboard": MessageLookupByLibrary.simpleMessage("キーボードを表示"),
    "scientificSyntaxError": MessageLookupByLibrary.simpleMessage(
      "カーソル付近の式を確認してください。",
    ),
    "scientificTooDeep": MessageLookupByLibrary.simpleMessage("入れ子を減らしてください。"),
    "scientificTooLong": MessageLookupByLibrary.simpleMessage("式を短くしてください。"),
    "scientificUnknownFunction": m10,
    "scientificUnknownVariable": m11,
    "searchHistory": MessageLookupByLibrary.simpleMessage("履歴を検索"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "shakeToUndo": MessageLookupByLibrary.simpleMessage("シェイクで元に戻す"),
    "shakeToUndoDescription": MessageLookupByLibrary.simpleMessage(
      "端末を振って直前の入力を取り消します",
    ),
    "shortcutBackspace": MessageLookupByLibrary.simpleMessage("最後の1桁を削除"),
    "shortcutClear": MessageLookupByLibrary.simpleMessage("入力をクリア"),
    "shortcutEquals": MessageLookupByLibrary.simpleMessage("計算を実行"),
    "shortcutHistory": MessageLookupByLibrary.simpleMessage("履歴の表示切替"),
    "shortcutNumbers": MessageLookupByLibrary.simpleMessage("数字キーおよびテンキー"),
    "shortcutOperators": MessageLookupByLibrary.simpleMessage("四則演算、パーセント、小数点"),
    "shortcutPaste": MessageLookupByLibrary.simpleMessage("数値を貼り付け"),
    "shortcutRedo": MessageLookupByLibrary.simpleMessage("入力をやり直す"),
    "shortcutTools": MessageLookupByLibrary.simpleMessage("日常ツールを開く"),
    "shortcutUndo": MessageLookupByLibrary.simpleMessage("入力を元に戻す"),
    "soundEffects": MessageLookupByLibrary.simpleMessage("キー操作音"),
    "soundEffectsDescription": MessageLookupByLibrary.simpleMessage(
      "キーを押したときに控えめなクリック音を鳴らします",
    ),
    "subtract": MessageLookupByLibrary.simpleMessage("引く"),
    "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
    "thousandsSeparator": MessageLookupByLibrary.simpleMessage("桁区切り"),
    "thousandsSeparatorDescription": MessageLookupByLibrary.simpleMessage(
      "1,234.56 のように大きな数値を3桁ごとに区切ります",
    ),
    "undo": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unitConverter": MessageLookupByLibrary.simpleMessage("単位換算"),
    "useCurrentDisplay": m12,
  };
}
