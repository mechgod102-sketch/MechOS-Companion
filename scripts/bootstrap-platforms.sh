#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo "Flutter SDK is required." >&2; exit 1; }
flutter create . --platforms=android,ios --org com.mechos --project-name mechos_companion_mobile
# flutter create adds its stock MyApp widget test on a fresh CI runner. This
# project uses MechOSCompanionApp and has its own optimization report tests.
rm -f test/widget_test.dart
python3 scripts/apply_platform_patches.py
flutter pub get
echo "Android/iOS host projects generated and patched."
