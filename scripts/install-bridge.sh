#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install the bridge files." >&2
  exit 1
fi

sudo install -Dm755 mechos_bridge/server.py /usr/lib/mechos-companion-bridge/server.py
sudo install -Dm755 mechos_bridge/server_v012.py /usr/lib/mechos-companion-bridge/server_v012.py
sudo install -Dm755 mechos_bridge/push_dispatcher.py /usr/lib/mechos-companion-bridge/push_dispatcher.py
sudo install -Dm644 mechos_bridge/mechos-companion-bridge.service /usr/lib/systemd/user/mechos-companion-bridge.service
sudo install -Dm644 mechos_bridge/mechos-companion-push.service /usr/lib/systemd/user/mechos-companion-push.service
systemctl --user daemon-reload
systemctl --user enable --now mechos-companion-bridge.service
systemctl --user enable --now mechos-companion-push.service

echo "MechOS Companion Bridge 0.1.3 + Remote Access push dispatcher installed for the current user."
echo "View the pairing code with: journalctl --user -u mechos-companion-bridge -n 30"
echo "View background push status with: journalctl --user -u mechos-companion-push -n 30"
echo "For away-from-home access, connect the MechOS device and phone through Tailscale/WireGuard; do not router-port-forward port 47831."
