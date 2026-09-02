# MechOS Companion Bridge API — v0.1.1

Default local port: `47831`.

## Authentication

`POST /v1/pair` accepts the one-time six-digit pairing code shown by the bridge and returns a per-device bearer token. All endpoints except `/v1/health` and `/v1/pair` require that bearer token.

The phone cannot submit arbitrary commands. Remote actions are mapped to a fixed bridge allow-list of MechOS helper commands.

## Endpoints

- `GET /v1/health` — bridge version/health.
- `POST /v1/pair` — pair a phone and issue its token.
- `GET /v1/status` — MechOS version, hardware summary, memory/storage, session, update state, RadarAI state.
- `GET /v1/radarai/alerts` — current RadarAI alert records when available.
- `GET /v1/optimization/report` — calculates a share-ready optimization report with score, live CPU/GPU/RAM/storage metrics, optional temperature, findings, fixes, RadarAI state, update state, and a unique report ID.
- `POST /v1/action` — approved remote action only.

## Optimization report notes

The report is generated locally on the paired MechOS machine. CPU utilization is sampled from `/proc/stat`; memory and storage are read from local Linux system data; GPU utilization is read from `nvidia-smi` or Linux DRM sysfs when available; temperatures are read from Linux thermal/hwmon sensors when available. Missing metrics are reported as unavailable rather than guessed.

The mobile app renders the JSON report into either a **1080×1920 full PNG** or a **1080×1350 summary PNG**. It can save the image to the phone and open the system share sheet for Discord or another app.
