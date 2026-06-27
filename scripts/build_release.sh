#!/usr/bin/env bash
#
# Build a production release with the real AdMob ad unit IDs injected.
#
# Debug builds (`flutter run`) automatically use Google's test ad IDs, so they
# need no flags. Release builds must inject the git-ignored production IDs from
# ad_ids.release.json via --dart-define-from-file.
#
# Usage:
#   scripts/build_release.sh apk            # Android APK
#   scripts/build_release.sh appbundle      # Android App Bundle (Play Store)
#   scripts/build_release.sh ipa            # iOS archive
#
# Any extra args are forwarded to `flutter build`, e.g.:
#   scripts/build_release.sh appbundle --build-number=29
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-appbundle}"
shift || true

ID_FILE="ad_ids.release.json"
if [[ ! -f "$ID_FILE" ]]; then
  echo "❌ $ID_FILE not found."
  echo "   Copy ad_ids.release.example.json to $ID_FILE and fill in your real AdMob IDs."
  exit 1
fi

echo "🚀 flutter build $TARGET --release --dart-define-from-file=$ID_FILE $*"
flutter build "$TARGET" --release --dart-define-from-file="$ID_FILE" "$@"
