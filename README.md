# Simple Calculator

A clean, themeable calculator app built with Flutter — available on iOS.

## Download

[![App Store](https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg)](https://apps.apple.com/app/id1611258200)

## Features

- **18 themes** — switch between colour themes from the settings page
- **Localization** — English, Simplified Chinese, Traditional Chinese
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
