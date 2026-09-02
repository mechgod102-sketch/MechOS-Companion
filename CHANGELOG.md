# Changelog

## 0.1.2

- Added live CPU/GPU/RAM/storage/temperature telemetry and mobile history graphs.
- Added MechOS updater phase/progress display using structured updater status files.
- Added game compatibility browser backed by MechOS compatibility profiles.
- Added hardware + RadarAI notification center with live authenticated refresh.
- Added paired mobile-device inventory without exposing device credentials.
- Added Developer Bug Report bundles for Discord/GitHub.
- Developer bundles include a summary PNG, structured JSON, GitHub-ready Markdown, and bounded MechOS service-log excerpts.
- Added MechOS Bridge v0.1.2 feature endpoints for performance, compatibility, update progress, notifications, paired devices, and developer reports.
- Reorganized mobile navigation into Home, Live, Optimize, Games, and More.
- Kept background push provider-neutral so APNs/FCM can be connected later without changing the bridge alert contract.

## 0.1.1

- Added Optimize navigation tab.
- Added live optimization report endpoint to MechOS Bridge.
- Added CPU/RAM/storage/GPU/temperature metric collection with safe unavailable fallbacks.
- Added optimization score, findings, recommendations, report IDs, and build-channel data.
- Added full 1080×1920 report PNG generator.
- Added compact 1080×1350 summary report PNG generator.
- Added generated-image preview.
- Added Save to Phone / MechOS Reports album.
- Added Share to Discord through the OS share sheet.
- Added Android/iOS gallery permission patches.
- Fixed update-state parsing so “no updates” is not treated as an available update.

## 0.1.0

- Initial Android/iPhone Flutter companion source.
- Pairing, dashboard, RadarAI, updates, session switching, and safe power controls.
