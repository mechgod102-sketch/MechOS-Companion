# MechOS Companion Bridge API — v0.2.1

Default local port: `47831`.

## Authentication

`POST /v1/pair` accepts the one-time six-digit pairing code shown by the bridge and returns a per-device bearer token. When MechOS Anywhere is configured, the pairing response also includes the device's remote relay URL. All endpoints except `/v1/health` and `/v1/pair` require that bearer token.

The phone cannot submit arbitrary commands. Remote actions are mapped to a fixed bridge allow-list of MechOS helper commands, remote store installs are limited to the bridge's approved catalog, and remote input accepts only validated pointer/scroll/key/text event types. Arbitrary shell text, package IDs, repositories, and download URLs are not accepted from the phone.

## Connection modes

The mobile app stores the local bridge URL and, when available, a MechOS Anywhere remote device URL. It tries the LAN URL first and falls back to the remote URL when the local PC cannot be reached. This allows the same paired device to work over Wi-Fi or cellular data without exposing the bridge directly through router port forwarding.

Local discovery uses mDNS/Bonjour service type `_mechos-companion._tcp`.

## Endpoints

- `GET /v1/health` — bridge version/health.
- `POST /v1/pair` — pair a phone and issue its token; may include `remote_url`.
- `GET /v1/status` — MechOS version, hardware summary, memory/storage, session, update state, RadarAI state.
- `GET /v1/radarai/alerts` — current RadarAI alert records when available.
- `GET /v1/optimization/report` — calculates a share-ready optimization report with score, live CPU/GPU/RAM/storage metrics, optional temperature, findings, fixes, RadarAI state, update state, and a unique report ID.
- `POST /v1/action` — approved remote action only.
- `GET /v1/store/catalog` — approved Unified Store and Creator Store items.
- `POST /v1/store/install` — queue one approved catalog item for installation on the paired PC.
- `GET /v1/store/downloads` — current/recent remote install queue state.
- `GET /v1/remote/frame?quality=55` — returns one authenticated desktop frame as base64 image data plus frame dimensions.
- `POST /v1/remote/input` — sends one validated remote input event (`tap`, `click`, `scroll`, `key`, or bounded `text`).

## Remote Control

Remote Control uses repeated authenticated screen frames rather than exposing a raw desktop server port. The bridge captures the active desktop through the first supported local capture tool it finds: `grim`, Spectacle, `gnome-screenshot`, or `scrot`. Frame payloads are capped before relay forwarding.

For input, the bridge prefers `ydotool` for Wayland and falls back to `xdotool` for X11. The phone sends normalized pointer coordinates between 0 and 1 so the bridge can map touch positions to the current desktop resolution. Keyboard input is limited to an approved key map; text input is bounded to 500 characters and is passed as process input/arguments without shell evaluation.

Remote Control uses the same bearer token and local-first/MechOS Anywhere connection path as status, RadarAI, and store operations.

## RadarAI and update notifications

The mobile app checks `/v1/status` and `/v1/radarai/alerts` while active and through periodic background work when Android/iOS grants background execution time. New RadarAI alert states create local phone notifications. Identical alerts are suppressed until the condition clears and returns.

When `update_available` changes from false to true, Companion posts a MechOS system update notification. The **Update PC** notification action opens/uses the paired Companion session and requests the existing allow-listed `update_install` action. Android background checks use WorkManager; iOS uses system-managed Background Fetch, so iOS decides when background checks run.

## Store install safety

The bridge first uses `mechos-store-cli` when available. Otherwise, catalog entries with a known Flatpak application ID can be installed through the local `flatpak` command. The mobile app sends only the catalog `item_id`; it cannot supply a command, package identifier, repository, or URL.

## MechOS Anywhere relay

`mechos_relay/server.py` is the reference relay implementation. A PC configured with `MECHOS_RELAY_URL`, `MECHOS_RELAY_DEVICE_ID`, and `MECHOS_RELAY_SECRET` maintains an outbound long-poll connection to the relay. The public device URL is returned to the phone after local pairing.

The relay service must be placed behind HTTPS before internet exposure. The PC still validates the normal paired-device bearer token for forwarded Companion API calls. The reference relay provides encrypted transport when deployed behind HTTPS, but it does not yet provide application-layer end-to-end encryption through the relay itself.

## Optimization report notes

The report is generated locally on the paired MechOS machine. CPU utilization is sampled from `/proc/stat`; memory and storage are read from local Linux system data; GPU utilization is read from `nvidia-smi` or Linux DRM sysfs when available; temperatures are read from Linux thermal/hwmon sensors when available. Missing metrics are reported as unavailable rather than guessed.

The mobile app renders the JSON report into either a **1080×1920 full PNG** or a **1080×1350 summary PNG**. It can save the image to the phone and open the system share sheet for Discord or another app.
