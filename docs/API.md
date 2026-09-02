# MechOS Companion Bridge API — v0.1.2

Default local port: `47831`.

## Authentication

`POST /v1/pair` accepts the one-time six-digit pairing code shown by the bridge and returns a per-device bearer token. All endpoints except `/v1/health` and `/v1/pair` require that bearer token.

The phone cannot submit arbitrary commands. Remote actions are mapped to a fixed bridge allow-list of MechOS helper commands.

## Core endpoints

- `GET /v1/health` — bridge version/health.
- `POST /v1/pair` — pair a phone and issue its device credential.
- `GET /v1/status` — MechOS version, hardware summary, memory/storage, session, update state, RadarAI state.
- `GET /v1/radarai/alerts` — current RadarAI alert records when available.
- `GET /v1/optimization/report` — calculates a share-ready optimization report with score, live CPU/GPU/RAM/storage metrics, optional temperature, findings, fixes, RadarAI state, update state, and a unique report ID.
- `POST /v1/action` — approved remote action only.

## New v0.1.2 endpoints

- `GET /v1/performance/live` — live CPU, GPU, RAM, storage, temperature, and timestamp for mobile graphs.
- `GET /v1/games/compatibility` — normalized MechOS game compatibility catalog entries.
- `GET /v1/update/progress` — updater state, current phase, progress percentage, and message.
- `GET /v1/notifications` — normalized RadarAI plus hardware warning feed.
- `GET /v1/devices` — safe paired-mobile metadata. Pairing credentials are never returned.
- `GET /v1/developer/bug-report` — developer diagnostic bundle containing an optimization report, notifications, update status, catalog count, and bounded service-log excerpts.

## Game compatibility sources

The bridge looks for a MechOS compatibility catalog at:

- `/usr/share/mechos/compatibility/games.json`
- `/var/lib/mechos/compatibility/games.json`
- `~/.local/share/mechos/compatibility/games.json`

If no catalog file is present, it can use the fixed helper command `mechos-game-compat --list --json`. It does not execute user-supplied commands.

## Update progress contract

The bridge reads a structured updater status file from `/run/mechos-update/status.json` or `~/.local/state/mechos-update/status.json`. Recommended fields are:

```json
{
  "state": "downloading",
  "progress": 64,
  "phase": "Downloading packages",
  "message": "Applying MechOS update"
}
```

If no progress file is present, the endpoint reports the normal update-check state instead of inventing progress.

## Hardware notifications

The v0.1.2 feed can surface high temperature, high storage usage, extreme memory pressure, and RadarAI alerts. The mobile app polls this authenticated feed while it is active. True background push delivery is intentionally provider-neutral; an APNs/FCM provider can be connected later without changing the diagnostic feed contract.

## Developer report bundle

`GET /v1/developer/bug-report` creates a bounded support bundle. The phone turns it into:

- a Discord-ready optimization PNG;
- a structured JSON diagnostic file;
- a GitHub-ready Markdown issue file.

Service logs are limited to recent excerpts for the MechOS Companion Bridge, RadarAI, and MechOS updater. The endpoint does not expose pairing credentials or arbitrary filesystem content.

## Optimization report notes

CPU utilization is sampled from `/proc/stat`; memory and storage are read from local Linux system data; GPU utilization is read from `nvidia-smi` or Linux DRM sysfs when available; temperatures are read from Linux thermal/hwmon sensors when available. Missing metrics are reported as unavailable rather than guessed.

The mobile app renders the report into either a **1080×1920 full PNG** or a **1080×1350 summary PNG**. It can save the image to the phone and open the system share sheet for Discord or another app.
