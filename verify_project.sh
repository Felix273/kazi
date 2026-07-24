#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f pubspec.yaml || ! -d lib || ! -f lib/main.dart ]]; then
  echo "Error: run this script from the Kazi project root (the folder containing pubspec.yaml and lib/main.dart)." >&2
  exit 1
fi

echo "Project root: $(pwd)"
flutter clean
rm -rf .dart_tool
flutter pub get
flutter analyze
flutter test
flutter build apk --debug

echo "Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
