#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

command -v flutter >/dev/null || { echo "Flutter SDK is required." >&2; exit 1; }

flutter create . --platforms=android,ios --org com.mechos --project-name mechos_companion_mobile

# flutter create adds its stock MyApp widget test on a fresh project. This
# project uses MechOSCompanionApp and has its own tests.
rm -f test/widget_test.dart

python3 "$SCRIPT_DIR/apply_platform_patches.py"
flutter pub get

echo "Android/iOS host projects generated and patched in: $ROOT_DIR"
