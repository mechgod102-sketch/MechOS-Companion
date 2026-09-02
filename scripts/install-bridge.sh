#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install the bridge files." >&2
  exit 1
fi

sudo install -Dm755 mechos_bridge/server.py /usr/lib/mechos-companion-bridge/server.py
sudo install -Dm644 mechos_bridge/mechos-companion-bridge.service /usr/lib/systemd/user/mechos-companion-bridge.service
systemctl --user daemon-reload
systemctl --user enable --now mechos-companion-bridge.service

echo "MechOS Companion Bridge 0.1.1 installed for the current user."
echo "View the pairing code with: journalctl --user -u mechos-companion-bridge -n 30"
