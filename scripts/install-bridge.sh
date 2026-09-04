#!/usr/bin/env bash
set -euo pipefail

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install the bridge files." >&2
  exit 1
fi

sudo install -Dm755 mechos_bridge/server.py /usr/lib/mechos-companion-bridge/server.py
sudo install -Dm755 mechos_bridge/server_v020.py /usr/lib/mechos-companion-bridge/server_v020.py
sudo install -Dm644 mechos_bridge/mechos-companion-bridge.service /usr/lib/systemd/user/mechos-companion-bridge.service

# Advertise the PC to the mobile app when Avahi/mDNS is available.
if command -v avahi-daemon >/dev/null 2>&1 || [ -d /etc/avahi ]; then
  sudo install -Dm644 mechos_bridge/mechos-companion.avahi.service /etc/avahi/services/mechos-companion.service
  sudo systemctl try-reload-or-restart avahi-daemon.service >/dev/null 2>&1 || true
fi

mkdir -p "$HOME/.config/mechos-companion-bridge"
if [ ! -f "$HOME/.config/mechos-companion-bridge/relay.env" ]; then
  cat > "$HOME/.config/mechos-companion-bridge/relay.env" <<'EOF'
# Optional MechOS Anywhere configuration.
# The relay must be exposed through HTTPS before cellular/remote access is enabled.
# MECHOS_RELAY_URL=https://relay.example.com
# MECHOS_RELAY_PUBLIC_URL=https://relay.example.com
# MECHOS_RELAY_DEVICE_ID=my-mechos-pc
# MECHOS_RELAY_SECRET=replace-with-a-long-random-secret
EOF
  chmod 600 "$HOME/.config/mechos-companion-bridge/relay.env"
fi

systemctl --user daemon-reload
systemctl --user enable --now mechos-companion-bridge.service

echo "MechOS Companion Bridge 0.2.1 installed for the current user."
echo "View the pairing code with: journalctl --user -u mechos-companion-bridge -n 30"
echo "Optional remote access config: ~/.config/mechos-companion-bridge/relay.env"

echo
if command -v grim >/dev/null 2>&1 || command -v spectacle >/dev/null 2>&1 || command -v gnome-screenshot >/dev/null 2>&1 || command -v scrot >/dev/null 2>&1; then
  echo "Remote Control screen capture: ready"
else
  echo "Remote Control screen capture: missing (MechOS image should provide grim or the desktop screenshot utility)"
fi

if command -v ydotool >/dev/null 2>&1 || command -v xdotool >/dev/null 2>&1; then
  echo "Remote Control input: ready"
else
  echo "Remote Control input: missing (MechOS image should provide ydotool for Wayland or xdotool for X11)"
fi
