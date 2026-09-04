# Changelog

## 0.2.1

- Added authenticated Remote Control screen streaming from the MechOS PC to the companion phone.
- Added tap-to-click, left/right click, scrolling, approved keyboard keys, and bounded text input for remote control.
- Added Remote Control entry points in Tools, System Controls, and Home Quick Actions.
- Added Quick Actions for RadarAI scan, Lock, Sleep, Update Check, and Update PC.
- Added RadarAI phone notifications with duplicate suppression until an alert clears and returns.
- Added MechOS update-available notifications with an **Update PC** notification action.
- Added background status checks with Android WorkManager and iOS Background Fetch when the OS grants background execution time.
- Added notification permission/settings UI and Android notification icon/permission setup.
- Added iOS background fetch mode and raised iOS deployment target to 14.0 for background monitoring support.
- Added bridge screen-capture fallbacks for grim, Spectacle, gnome-screenshot, and scrot.
- Added remote input support through ydotool on Wayland or xdotool on X11.
- Added allow-listed Lock and Sleep power actions.
- Bumped mobile build version to `0.2.1+4`.

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
