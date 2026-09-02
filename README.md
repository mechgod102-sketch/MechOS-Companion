# MechOS Companion Mobile 0.1.3

Flutter companion app for Android and iPhone, paired with a MechOS PC or Steam Deck through the authenticated MechOS Companion Bridge.

## v0.1.3 — Away-from-home Remote Access

The Companion can now keep working when the phone is away from the MechOS machine's home Wi-Fi.

- Save a normal **Local** Bridge address and an optional **Remote private** address.
- Recommended remote transport: **Tailscale or WireGuard**.
- The app probes the current route, prefers Local, and automatically falls back to Remote.
- Home and More show **Local / Remote / Offline / Demo** connection state.
- Remote HTTP is accepted only for private address ranges, the Tailscale `100.64.0.0/10` range, loopback/private LAN ranges, or `.ts.net` names.
- Other remote hostnames must use HTTPS.
- **Do not router-port-forward TCP 47831.**

See `docs/REMOTE_ACCESS.md` for the complete setup and security design.

## Background alert plumbing

MechOS now includes `mechos_bridge/push_dispatcher.py` and the `mechos-companion-push.service` user service.

The dispatcher:

- checks severe hardware conditions;
- watches RadarAI warning/critical alerts;
- de-duplicates alerts with a cooldown;
- forwards JSON events to a fixed provider helper named `mechos-push-relay`;
- never executes alert text through a shell;
- contains no APNs/FCM credentials.

A production APNs/FCM relay and mobile device push registration still require provider credentials outside the public repository. Until those are configured, the live alert center continues to work over Local or Remote Access while the app is open.

## v0.1.2 feature set

### Live Performance

The **Live** tab polls the authenticated Bridge and graphs:

- CPU utilization
- GPU utilization when exposed by the driver
- RAM utilization
- storage utilization
- Linux sensor temperature when available
- MechOS update/download progress

Missing sensors are shown as unavailable rather than guessed.

### Game Compatibility

The **Games** tab searches compatibility information supplied by the paired MechOS system.

### Hardware + RadarAI Notifications

The notification center shows high temperature, storage pressure, severe memory pressure, and RadarAI alerts.

### Developer Bug Reports

The Developer Bug Report workflow can package:

- Discord-ready 1080×1350 optimization PNG
- structured JSON diagnostics
- GitHub-ready Markdown
- optimization score and findings
- current hardware metrics
- RadarAI warnings
- update/session state
- bounded recent Bridge/RadarAI/updater log excerpts

The phone uses the normal system share sheet so you choose the destination.

### Paired Mobile Devices

The app can display companion devices paired with the Bridge without exposing their bearer credentials.

## Optimization Reports

The **Optimize** tab can:

- run a live optimization scan;
- calculate a 0–100 score;
- show prioritized findings and recommended fixes;
- generate a **1080×1920 full PNG** or **1080×1350 summary PNG**;
- save images to the **MechOS Reports** album;
- share reports through the system share sheet;
- include a unique report ID and timestamp.

## Existing controls

- six-digit one-time pairing
- Android Keystore / Apple Keychain credential storage
- MechOS dashboard
- MechScope/Desktop switching
- MechOS update check/install controls
- RadarAI health, alerts, and quick scan
- restart/shutdown with confirmation dialogs
- Demo Mode
- dark MechOS visual theme

All remote actions remain limited to the Bridge's explicit allow-list. The phone cannot submit arbitrary shell commands.

## Navigation

`Home → Live → Optimize → Games → More`

More contains Remote Access, Notifications, RadarAI, MechOS Controls, Developer Bug Report, Paired Mobile Devices, and Settings.

## Install/update the MechOS Bridge

On the MechOS machine:

```bash
./scripts/install-bridge.sh
```

That installs and enables both:

- `mechos-companion-bridge.service`
- `mechos-companion-push.service`

View the current pairing code:

```bash
journalctl --user -u mechos-companion-bridge -n 30
```

View background push-dispatcher status:

```bash
journalctl --user -u mechos-companion-push -n 30
```

Default Bridge port: `47831`.

## Flutter build

Generate current Android/iOS host projects and apply MechOS patches:

```bash
./scripts/bootstrap-platforms.sh
```

Validate and test:

```bash
python3 scripts/validate_source.py
flutter analyze
flutter test
```

Build Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

The GitHub Android workflow uploads `MechOS-Companion-Android` containing the APK/AAB when successful.

Build iPhone on macOS:

```bash
flutter build ios --release
```

The GitHub iOS workflow currently validates an **unsigned** iPhone build. Physical-device/TestFlight distribution still requires Apple Developer signing.

## Application identity

- Android application ID: `com.mechos.companion`
- iOS bundle ID: `com.mechos.companion`
- App name: `MechOS Companion`
- Current source version: `0.1.3+4`

## Security summary

- no arbitrary shell-command endpoint
- explicit action allow-list
- random per-device bearer token
- OS-backed secure token storage on mobile
- local/private remote route preference and failover
- no recommended public router port forwarding
- HTTPS required for non-private remote hostnames
- read-only optimization/telemetry scans
- provider credentials kept out of source control
- background dispatcher invokes only a fixed `mechos-push-relay` helper and passes JSON on stdin

See `docs/API.md`, `docs/BUILDING.md`, and `docs/REMOTE_ACCESS.md` for implementation details.
