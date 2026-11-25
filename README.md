# SwiftSum (Simple Calculator)

A clean, themeable, offline-first calculator app built with Flutter — available on **iOS**, **Android**, and **macOS**.

## Download

[![App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/nz/app/swiftsum-simple-calculator/id1610829871)

## Features

- **18 named themes + Custom theme builder** — switch palettes, sync automatically with system light/dark mode, or build a custom palette with live WCAG contrast checks (Premium)
- **High contrast** — a saved accessibility option improves number and control contrast while preserving your selected colour theme
- **9 in-app languages** — English, Simplified Chinese, Traditional Chinese, Spanish, German, French, Japanese, Korean, and Portuguese
- **Rock-steady fixed-height display** — live calculation preview (`= …`) and expression rows use reserved slots so the display never jumps while typing
- **Smart `C` / `AC`, Undo & Redo** — clear only the current entry (`C`) or all clear (`AC` / long-press `C`), with toolbar Undo/Redo buttons and shake-to-undo on mobile
- **Memory & repeat equals** — optional `MC`, `MR`, `M+`, `M−` memory bar, repeat `=` toggle, key click sounds, and thousands / comma-decimal number formatting
- **Calculation history** — retain up to 100 calculations across restarts, search and edit past calculations, pin & name entries, sum visible entries, reuse results, swipe to delete (with undo), or copy as plain text / TSV
- **Copy, paste & operand correction** — tap the display to copy the number, copy full equations, paste formatted or scientific numbers, and tap either operand above the display to edit it without shifting the calculator layout
- **Everyday tools** — tip & bill splitter (with per-person round-up), multi-item unit price comparator, discount & sales tax calculator, percentage change & profit margin, date difference & offset calculator, loan & compound interest calculator, and offline currency converter (with optional live ECB rate refresh & custom rate override)
- **Offline unit converter** — convert across 8 categories (length, mass, volume, temperature, area, speed, data, time) with per-category remembered pairs, quick pinned presets, all-units breakdown, and one-tap reuse in the calculator
- **SwiftSum Premium** — scientific calculator (with fixed-height live preview, fraction mode, engineering notation, Ans, history, and function graphing with roots, intersections & value tables), programmer base converter (`DEC`/`HEX`/`OCT`/`BIN` + bitwise ops), reusable formulas with scenario comparisons, custom theme builder, and ad-free experience
- **Backup & restore (JSON)** — export and restore your history, saved formulas, themes, input settings, and pinned unit pairs across devices
- **Platform polish** — macOS always-on-top window pin & remembered window size, iOS & Android Home Screen Quick Actions, tablet/desktop history sidebar, full keyboard shortcuts, and localized screen-reader support
- **AdMob integration** — banner, interstitial, and app open ads (removed with Premium)

## Tech Stack

| Area | Package |
|---|---|
| State management | `provider` |
| Ads | `google_mobile_ads` |
| Tracking consent | `app_tracking_transparency` |
| Localization | `flutter_localizations` + `intl` |
| In-app review | `in_app_review` |
| Storage | `shared_preferences` |

## Project Structure

```
lib/
├── main.dart                     # App entry, locale resolution, MobileAds & macOS window setup
├── calculator.dart               # Main screen, toolbar (Undo/Redo/Pin), operand editor & sidebar
├── display.dart                  # Fixed-height display with live preview & swipe-to-backspace
├── key_pad.dart                  # Calculator keypad with active operator & smart C/AC
├── processor.dart                # Calculation, smart clear, undo/redo, memory & history logic
├── history_sheet.dart            # Searchable, grouped, pinnable history sheet & sidebar
├── everyday_tools_page.dart      # Tip, unit price, discount/tax, margin, date, loan & compound
├── currency_converter_page.dart  # Offline currency converter with live refresh & custom rates
├── unit_converter_page.dart      # Offline unit converter across 8 categories with quick presets
├── more_page.dart                # Settings, themes, input preferences & JSON backup/restore
├── premium/                      # Scientific, programmer base, graphing, formulas & custom theme
└── util/
    ├── ads_manager.dart          # AdMob ID resolution + AppOpenAdManager
    ├── backup_manager.dart       # Versioned JSON export & validated atomic import
    ├── currency_converter.dart   # Offline reference rates, custom overrides & ECB refresh
    ├── desktop_window_helper.dart# macOS always-on-top persistence & native channel
    ├── quick_actions_service.dart# iOS & Android Home Screen Quick Actions router
    ├── theme_model.dart          # Theme state, contrast, system sync & custom palettes
    ├── storage_manager.dart      # Preferences persistence
    └── local_storage.dart        # SharedPreferences wrapper
```

## AdMob Setup

Ad unit IDs are injected at build time — no secrets in source.

| Build | Ad IDs used | How |
|---|---|---|
| Debug / `flutter run` | Google test IDs (hardcoded) | automatic |
| Release | Real production IDs | `--dart-define-from-file=ad_ids.release.json` |

**To set up release builds:**

```bash
# 1. Copy the example and fill in your real AdMob IDs
cp ad_ids.release.example.json ad_ids.release.json

# 2. Build (ad_ids.release.json is git-ignored)
scripts/build_release.sh appbundle   # Android
scripts/build_release.sh ipa         # iOS
```

The `ADMOB_APP_ID_*` keys inject into `AndroidManifest.xml` (via `manifestPlaceholders`) and `Info.plist` (via xcconfig variable substitution), so no production App IDs appear in committed source.

## Getting Started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x. To run the native desktop app, use `flutter run -d macos` on a Mac with Xcode. SwiftSum supports macOS 12 and later.

The Mac App Store target uses `com.appsbay.simpleCalculatorMac` and its own SwiftSum Premium purchase. Premium unlocks the scientific calculator, programmer mode, graphing, custom themes, and reusable formulas on Mac. Use **Restore Purchases** with the Apple Account that purchased Premium for Mac.
