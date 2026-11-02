# Simple Calculator

A clean, themeable calculator app built with Flutter — available on iOS.

## Download

[![App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/nz/app/swiftsum-simple-calculator/id1610829871)

## Features

- **18 themes** — switch between colour themes from the settings page
- **High contrast** — a saved accessibility option improves number and control contrast while preserving your selected colour theme
- **Localization** — English, Simplified Chinese, Traditional Chinese
- **Undo** — restore recent input with the toolbar button or shake-to-undo on supported phones
- **Calculation history** — retain up to 100 calculations across restarts, search them, reuse results, swipe to delete (with undo), or clear saved history
- **Copy and paste** — tap the display to copy the unformatted number, copy a full calculation from history, or paste a number (plain, thousands-grouped, or scientific notation)
- **Bulk history copying** — copy all saved calculations or just the current search matches as plain text
- **Input settings** — independently enable or disable haptic feedback and shake-to-undo
- **Keyboard support** — use number keys or the numeric keypad, operators, Enter for equals, Backspace to delete, Escape to clear, Ctrl/Cmd+Z to undo, and Ctrl/Cmd+V to paste
- **Tips and shortcuts** — an in-app help page in settings explains gestures and keyboard shortcuts
- **Accessible controls** — localized screen-reader labels and actions for the keypad and result display
- **AdMob integration** — banner, interstitial, and app open ads
- Supports iOS, Android, and macOS desktop

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
├── main.dart               # App entry, MobileAds init, App Open ad wiring
├── calculator.dart         # Main screen with banner ad
├── display.dart            # Result display widget
├── key-pad.dart            # Calculator keypad
├── processor.dart          # Calculation logic
├── more_page.dart          # Settings / themes / more apps (interstitial ad)
└── util/
    ├── ads_manager.dart    # AdMob ID resolution + AppOpenAdManager
    ├── ThemeModel.dart     # Theme state
    ├── StorageManager.dart # Theme persistence
    └── local_storage.dart  # SharedPreferences wrapper
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

Requires Flutter 3.x. For macOS, the window size is fixed at 350×700.
