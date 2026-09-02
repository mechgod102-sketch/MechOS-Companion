# MechOS Companion Mobile 0.1.2

Flutter source for the Android + iPhone MechOS Companion app.

## New in v0.1.2

### Live Performance

The **Live** tab polls the authenticated MechOS Bridge and builds mobile graphs for:

- CPU utilization
- GPU utilization when exposed by the driver
- RAM utilization
- storage utilization
- Linux sensor temperature when available
- MechOS update/download progress

No metric is guessed when a sensor is missing.

### Game Compatibility

The **Games** tab searches and displays the compatibility catalog supplied by the paired MechOS system. The bridge reads MechOS compatibility JSON files or the fixed `mechos-game-compat --list --json` helper when available.

### Hardware + RadarAI Notifications

The companion now has a notification center for high temperature, high storage usage, severe memory pressure, and RadarAI alerts. The feed refreshes while the app is active. The bridge contract is provider-neutral so APNs/FCM background delivery can be added later without changing the hardware-alert API.

### Paired Device Management

The **Paired Mobile Devices** page shows the phones and tablets paired with the current MechOS Bridge, including which entry represents the current phone. Pairing credentials are never displayed. v0.1.2 keeps cross-device removal disabled; the current phone can disconnect itself from Settings.

### Developer Bug Report Bundle

The **Developer Bug Report** tool creates a shareable package for your developer Discord or GitHub workflow:

- Discord-ready 1080×1350 optimization PNG
- structured JSON diagnostic report
- GitHub-ready Markdown issue file
- optimization score and findings
- current hardware metrics
- RadarAI warnings
- update/session state
- bounded recent log excerpts for the Companion Bridge, RadarAI, and MechOS updater

The phone opens the normal system share sheet so you choose Discord, GitHub, Files, email, or another installed destination.

## Optimization Reports from v0.1.1

The **Optimize** tab remains available and can:

- run a live optimization scan;
- calculate a 0–100 optimization score;
- show prioritized findings and recommended fixes;
- generate a **1080×1920 full PNG** or **1080×1350 summary PNG** locally on the phone;
- save reports to the **MechOS Reports** photo album;
- share a report image through the phone share sheet;
- include a unique report ID and timestamp.

## Existing companion features

- One-time-code pairing with a MechOS PC / Steam Deck.
- Device credential stored using Android Keystore / Apple Keychain.
- MechOS system dashboard.
- MechScope/Desktop session controls.
- MechOS update check/install controls.
- RadarAI health, alerts, and quick scan.
- Restart/shutdown controls with confirmation dialogs.
- Demo Mode.
- Dark MechOS visual theme.

## Build prerequisites

Use a current Flutter toolchain compatible with Dart 3.9+. Android builds can be created on Windows, Linux, or macOS. **iPhone/iOS builds require macOS with Xcode** for Apple signing/building.

## Generate Android + iOS host projects

```bash
./scripts/bootstrap-platforms.sh
```

Then test:

```bash
flutter analyze
flutter test
flutter run
```

Build Android APK:

```bash
flutter build apk --release
```

Android output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build a Play Store bundle:

```bash
flutter build appbundle --release
```

Build iPhone on macOS:

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode, choose your Apple signing team, and archive/install the app.

## Install or update the MechOS Bridge

From this project on the MechOS computer:

```bash
./scripts/install-bridge.sh
```

View the pairing code:

```bash
journalctl --user -u mechos-companion-bridge -n 30
```

Enter the computer's LAN address and six-digit pairing code on the phone. Default bridge port: **47831**.

## Update progress integration

For real download/install percentages, MechOS Updater should write structured status to one of:

```text
/run/mechos-update/status.json
~/.local/state/mechos-update/status.json
```

See `docs/API.md` for the status-file schema and all v0.1.2 endpoints.

## Security design

- The phone cannot send arbitrary shell commands.
- The bridge uses an explicit remote-action allow-list.
- Pairing creates a random per-device credential.
- Mobile credentials go into OS-backed secure storage.
- Power/session actions require confirmation in the app.
- Optimization and developer scans are read-only.
- Paired-device listing never returns pairing credentials.
- Developer logs are bounded to known MechOS user services.
- Report PNG generation happens locally on the phone.
- Trusted-LAN development still uses authenticated local HTTP. Add authenticated TLS/certificate pinning before exposing the bridge beyond the local network.

## MechOS helper commands expected

- `mechos-update --check`
- `mechos-update --install`
- `mechos-session-select --mechscope`
- `mechos-session-select --desktop`
- `radarai status`
- `radarai scan --quick`
- `mechos-power-control --restart`
- `mechos-power-control --shutdown`
- optional: `mechos-game-compat --list --json`

Missing helpers are reported to the app instead of falling back to arbitrary commands.

## GitHub build automation

GitHub Actions automatically builds Android and validates iOS on every push to `main`.

- Download **MechOS-Companion.apk** from the `MechOS-Companion-Android` workflow artifact for Android sideloading.
- The iOS workflow produces an **unsigned** build until Apple Developer signing credentials are configured.
- Application ID / bundle ID: `com.mechos.companion`.

See `docs/BUILDING.md` for details.
