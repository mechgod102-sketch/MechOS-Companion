#!/usr/bin/env python3
"""Provider-neutral MechOS Companion background alert dispatcher.

This service never contains APNs/FCM credentials. It watches local hardware and
RadarAI state, de-duplicates alerts, and sends JSON events to a fixed helper
named `mechos-push-relay` when that provider-specific helper is installed.
"""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

ALERTS = Path.home() / '.local' / 'state' / 'radarai' / 'alerts.json'
STATE_DIR = Path.home() / '.local' / 'state' / 'mechos-companion'
STATE_FILE = STATE_DIR / 'push-dispatcher.json'
RELAY = 'mechos-push-relay'
POLL_SECONDS = 60
COOLDOWN_SECONDS = 30 * 60


def _read_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def _load_state():
    value = _read_json(STATE_FILE, {})
    return value if isinstance(value, dict) else {}


def _save_state(value):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(value, indent=2))


def _temperature_c():
    values = []
    paths = list(Path('/sys/class/thermal').glob('thermal_zone*/temp'))
    paths += list(Path('/sys/class/hwmon').glob('hwmon*/temp*_input'))
    for path in paths:
        try:
            value = float(path.read_text().strip())
            if value > 500:
                value /= 1000
            if 10 <= value <= 125:
                values.append(value)
        except Exception:
            pass
    return round(max(values), 1) if values else None


def _memory_percent():
    total = available = 0
    try:
        for line in Path('/proc/meminfo').read_text().splitlines():
            if line.startswith('MemTotal:'):
                total = int(line.split()[1])
            elif line.startswith('MemAvailable:'):
                available = int(line.split()[1])
    except Exception:
        return None
    if total <= 0:
        return None
    return round((total - available) / total * 100, 1)


def _storage_percent():
    usage = shutil.disk_usage('/')
    if usage.total <= 0:
        return None
    return round((usage.total - usage.free) / usage.total * 100, 1)


def _radar_events():
    raw = _read_json(ALERTS, [])
    if isinstance(raw, dict):
        raw = raw.get('alerts', [])
    if not isinstance(raw, list):
        return []
    events = []
    for item in raw[:12]:
        if not isinstance(item, dict):
            continue
        severity = str(item.get('severity', 'info')).lower()
        if severity not in ('warning', 'critical', 'error'):
            continue
        events.append({
            'kind': 'radarai',
            'severity': severity,
            'title': str(item.get('title', 'RadarAI alert'))[:120],
            'detail': str(item.get('detail', 'RadarAI reported a system condition.'))[:300],
        })
    return events


def _hardware_events():
    events = []
    temp = _temperature_c()
    memory = _memory_percent()
    storage = _storage_percent()
    if temp is not None and temp >= 95:
        events.append({'kind': 'hardware', 'severity': 'critical', 'title': 'High system temperature', 'detail': f'A system sensor reached {temp:.0f}°C.'})
    elif temp is not None and temp >= 88:
        events.append({'kind': 'hardware', 'severity': 'warning', 'title': 'System temperature elevated', 'detail': f'A system sensor reached {temp:.0f}°C.'})
    if memory is not None and memory >= 94:
        events.append({'kind': 'hardware', 'severity': 'critical', 'title': 'Memory pressure is high', 'detail': f'System memory usage reached {memory:.0f}%.'})
    if storage is not None and storage >= 94:
        events.append({'kind': 'hardware', 'severity': 'critical', 'title': 'System storage nearly full', 'detail': f'System storage usage reached {storage:.0f}%.'})
    return events


def _event_key(event):
    payload = json.dumps(event, sort_keys=True).encode()
    return hashlib.sha256(payload).hexdigest()[:24]


def _send(event):
    relay = shutil.which(RELAY)
    if not relay:
        return False, 'provider relay not configured'
    payload = dict(event)
    payload['source'] = 'MechOS Companion'
    payload['generated_at'] = datetime.now(timezone.utc).isoformat()
    try:
        result = subprocess.run(
            [relay],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            timeout=15,
            check=False,
        )
        message = (result.stdout or result.stderr or '').strip()
        return result.returncode == 0, message or f'exit {result.returncode}'
    except Exception as exc:
        return False, str(exc)


def dispatch_once():
    state = _load_state()
    sent = state.get('sent', {}) if isinstance(state.get('sent'), dict) else {}
    now = int(time.time())
    changed = False
    for event in [*_hardware_events(), *_radar_events()]:
        key = _event_key(event)
        last = int(sent.get(key, 0) or 0)
        if now - last < COOLDOWN_SECONDS:
            continue
        ok, message = _send(event)
        if ok:
            sent[key] = now
            changed = True
            print(f"[push] sent: {event['title']}")
        elif message != 'provider relay not configured':
            print(f"[push] failed: {message}")
    if changed:
        # Keep the state file bounded.
        cutoff = now - 7 * 24 * 60 * 60
        state['sent'] = {k: v for k, v in sent.items() if int(v) >= cutoff}
        _save_state(state)


def main():
    print('MechOS Companion background push dispatcher')
    if not shutil.which(RELAY):
        print('Provider helper mechos-push-relay is not installed; waiting for provider configuration.')
    while True:
        dispatch_once()
        time.sleep(POLL_SECONDS)


if __name__ == '__main__':
    main()
