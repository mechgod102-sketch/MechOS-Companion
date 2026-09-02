# MechOS Companion Remote Access — v0.1.3

MechOS Companion can use the same authenticated Bridge API both at home and away from home without exposing the Bridge directly to the public internet.

## Recommended network design

1. Install a private networking solution such as Tailscale or WireGuard on the MechOS system.
2. Connect the phone to the same private network.
3. Keep the normal local Bridge address for home Wi-Fi, for example `http://mechos.local:47831`.
4. In **More → Remote Access**, save the private remote Bridge address.
5. The app probes the active route, prefers Local, and falls back to Remote automatically.

Examples of acceptable remote routes:

- `http://100.x.y.z:47831` for a Tailscale private address.
- `https://device-name.tailnet.ts.net:47831` when HTTPS is configured.
- an HTTPS hostname routed only through your private WireGuard network.

## Security rules

- Do **not** router-port-forward TCP 47831 to the internet.
- The Bridge still requires the per-device bearer token created during pairing.
- HTTP remote addresses are accepted by the app only for RFC1918/private ranges, loopback, the Tailscale CGNAT range `100.64.0.0/10`, or `.ts.net` names.
- Other remote hostnames must use HTTPS.
- Remote update, session, restart, and shutdown commands remain limited to the Bridge action allow-list and the app's confirmation flow.

## Local / Remote / Offline state

The Home and More screens show the current route:

- **Local** — the local Bridge address is reachable.
- **Remote** — the local route failed and the configured private remote route is active.
- **Offline** — neither trusted route is reachable.
- **Demo** — the app is running without a real MechOS connection.

## Background hardware and RadarAI alerts

The repo includes `mechos_bridge/push_dispatcher.py` plus a systemd user service. The dispatcher checks severe hardware conditions and RadarAI warnings and forwards de-duplicated JSON events to a fixed executable named `mechos-push-relay`.

`mechos-push-relay` is intentionally provider-specific and is **not** bundled with credentials. A production deployment can implement that helper using Android FCM, Apple APNs, or another approved notification provider. The dispatcher passes one JSON event on stdin and never executes event text through a shell.

Example event contract:

```json
{
  "kind": "hardware",
  "severity": "critical",
  "title": "High system temperature",
  "detail": "A system sensor reached 96°C.",
  "source": "MechOS Companion",
  "generated_at": "2026-09-02T12:00:00+00:00"
}
```

Until a provider-specific relay and mobile push registration are configured, live alert polling still works over Local or Remote Access while the Companion app is open.
