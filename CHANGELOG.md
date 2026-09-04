# Changelog

## 0.2.0

- Added automatic MechOS PC discovery over mDNS/Bonjour.
- Added upgraded cyber-style dark UI with new Home/Store/Tools/RadarAI/Settings navigation.
- Added MechOS Anywhere local-first connection fallback with an optional HTTPS relay route for cellular access.
- Added persistent remote relay configuration in secure app settings.
- Added Unified Store and Creator Store browsing from the companion app.
- Added remote install queue and download status tracking on the paired MechOS PC.
- Added bridge-side allowlisted store installs using `mechos-store-cli` when available, with Flatpak fallback for approved catalog entries.
- Added reference MechOS Anywhere relay service and outbound PC relay agent so the PC does not require router port forwarding.
- Added Avahi service advertisement for `_mechos-companion._tcp`.
- Added Android multicast/network permissions and iOS Bonjour service declarations.
- Bumped mobile build version to `0.2.0+3`.

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
