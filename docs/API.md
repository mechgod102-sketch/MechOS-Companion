# MechOS Companion Bridge API — v0.2.0

Default local port: `47831`.

## Authentication

`POST /v1/pair` accepts the one-time six-digit pairing code shown by the bridge and returns a per-device bearer token. When MechOS Anywhere is configured, the pairing response also includes the device's remote relay URL. All endpoints except `/v1/health` and `/v1/pair` require that bearer token.

The phone cannot submit arbitrary commands. Remote actions are mapped to a fixed bridge allow-list of MechOS helper commands, and remote store installs are limited to the bridge's approved catalog. Arbitrary shell text, package IDs, and download URLs are not accepted from the phone.

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

## Store install safety

The v0.2.0 bridge first uses `mechos-store-cli` when available. Otherwise, catalog entries with a known Flatpak application ID can be installed through the local `flatpak` command. The mobile app sends only the catalog `item_id`; it cannot supply a command, package identifier, repository, or URL.

## MechOS Anywhere relay

`mechos_relay/server.py` is the reference relay implementation. A PC configured with `MECHOS_RELAY_URL`, `MECHOS_RELAY_DEVICE_ID`, and `MECHOS_RELAY_SECRET` maintains an outbound long-poll connection to the relay. The public device URL is returned to the phone after local pairing.

The relay service must be placed behind HTTPS before internet exposure. The PC still validates the normal paired-device bearer token for forwarded Companion API calls. The reference v0.2.0 relay provides encrypted transport when deployed behind HTTPS, but it does not yet provide application-layer end-to-end encryption through the relay itself.

## Optimization report notes

The report is generated locally on the paired MechOS machine. CPU utilization is sampled from `/proc/stat`; memory and storage are read from local Linux system data; GPU utilization is read from `nvidia-smi` or Linux DRM sysfs when available; temperatures are read from Linux thermal/hwmon sensors when available. Missing metrics are reported as unavailable rather than guessed.

The mobile app renders the JSON report into either a **1080×1920 full PNG** or a **1080×1350 summary PNG**. It can save the image to the phone and open the system share sheet for Discord or another app.
