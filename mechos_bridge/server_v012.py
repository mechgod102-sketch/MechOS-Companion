#!/usr/bin/env python3
"""MechOS Companion Bridge v0.1.2 feature layer."""
from __future__ import annotations

import argparse
import hashlib
import json
import secrets
import socket
from datetime import datetime, timezone
from http.server import ThreadingHTTPServer
from pathlib import Path

import server as base

COMPATIBILITY_FILES = [
    Path('/usr/share/mechos/compatibility/games.json'),
    Path('/var/lib/mechos/compatibility/games.json'),
    Path.home() / '.local' / 'share' / 'mechos' / 'compatibility' / 'games.json',
]
UPDATE_STATUS_FILES = [
    Path('/run/mechos-update/status.json'),
    Path.home() / '.local' / 'state' / 'mechos-update' / 'status.json',
]


def performance_sample():
    ram_used, ram_total = base._meminfo()
    disk_used, disk_total = base._diskinfo()
    return {
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'cpu_percent': base.cpu_percent(),
        'gpu_percent': base.gpu_percent(),
        'ram_percent': round(0 if ram_total <= 0 else ram_used / ram_total * 100, 1),
        'storage_percent': round(0 if disk_total <= 0 else disk_used / disk_total * 100, 1),
        'temperature_c': base.temperature_c(),
    }


def _normalize_games(items, source):
    games = []
    if not isinstance(items, list):
        return games
    for item in items:
        if not isinstance(item, dict):
            continue
        games.append({
            'name': str(item.get('name', item.get('title', 'Unknown game')))[:160],
            'status': str(item.get('status', item.get('compatibility', 'Unknown')))[:80],
            'detail': str(item.get('detail', item.get('notes', '')))[:400],
            'source': str(item.get('source', source))[:100],
        })
    return games


def compatibility_catalog():
    for path in COMPATIBILITY_FILES:
        try:
            raw = json.loads(path.read_text())
        except Exception:
            continue
        items = raw.get('games', []) if isinstance(raw, dict) else raw
        games = _normalize_games(items, path.name)
        if games:
            return games

    ok, text = base.run(['mechos-game-compat', '--list', '--json'], 8)
    if ok:
        try:
            raw = json.loads(text)
            items = raw.get('games', raw) if isinstance(raw, dict) else raw
            return _normalize_games(items, 'mechos-game-compat')
        except Exception:
            pass
    return []


def update_progress():
    for path in UPDATE_STATUS_FILES:
        try:
            raw = json.loads(path.read_text())
            if not isinstance(raw, dict):
                continue
            progress = float(raw.get('progress', 0))
            return {
                'state': str(raw.get('state', 'idle'))[:40],
                'progress': max(0.0, min(100.0, progress)),
                'phase': str(raw.get('phase', ''))[:120],
                'message': str(raw.get('message', ''))[:300],
            }
        except Exception:
            continue

    available, msg = base.update_state()
    return {
        'state': 'available' if available else 'idle',
        'progress': 0,
        'phase': 'Update available' if available else 'Up to date',
        'message': msg[:300],
    }


def _notification(severity, title, detail, source='MechOS'):
    key = f'{source}:{title}:{detail}'.encode()
    return {
        'id': hashlib.sha256(key).hexdigest()[:12],
        'severity': severity,
        'title': title[:120],
        'detail': detail[:300],
        'source': source[:80],
        'created_at': datetime.now(timezone.utc).isoformat(),
    }


def notifications():
    result = []
    ram_used, ram_total = base._meminfo()
    disk_used, disk_total = base._diskinfo()
    ram_pct = 0 if ram_total <= 0 else ram_used / ram_total * 100
    disk_pct = 0 if disk_total <= 0 else disk_used / disk_total * 100
    temp = base.temperature_c()

    if temp is not None and temp >= 95:
        result.append(_notification('critical', 'High system temperature', f'A sensor reached {temp:.0f}°C.', 'Hardware'))
    elif temp is not None and temp >= 85:
        result.append(_notification('warning', 'System temperature elevated', f'A sensor reached {temp:.0f}°C.', 'Hardware'))

    if disk_pct >= 95:
        result.append(_notification('critical', 'Storage nearly full', f'The system drive is {disk_pct:.0f}% used.', 'Storage'))
    elif disk_pct >= 85:
        result.append(_notification('warning', 'Storage usage high', f'The system drive is {disk_pct:.0f}% used.', 'Storage'))

    if ram_pct >= 95:
        result.append(_notification('warning', 'Memory pressure high', f'System memory usage is {ram_pct:.0f}%.', 'Memory'))

    for alert in base.alerts()[:12]:
        if not isinstance(alert, dict):
            continue
        result.append(_notification(
            str(alert.get('severity', 'info')).lower(),
            str(alert.get('title', 'RadarAI alert')),
            str(alert.get('detail', 'RadarAI reported a system condition.')),
            'RadarAI',
        ))
    return result[:20]


def paired_devices(current_token=''):
    devices = []
    for token, item in base._load_tokens().items():
        if not isinstance(item, dict):
            item = {}
        devices.append({
            'id': hashlib.sha256(token.encode()).hexdigest()[:12],
            'name': str(item.get('name', 'Mobile device'))[:80],
            'paired_at': int(item.get('paired_at', 0) or 0),
            'current': secrets.compare_digest(token, current_token) if current_token else False,
        })
    devices.sort(key=lambda item: item['paired_at'], reverse=True)
    return devices


def _journal(unit):
    ok, text = base.run(['journalctl', '--user', '-u', unit, '-n', '80', '--no-pager'], 8)
    return text[-12000:] if ok else f'Unavailable: {text}'


def developer_bug_report():
    report = base.optimization_report()
    now = datetime.now(timezone.utc)
    report_id = f"MCHS-DEV-{now.strftime('%Y%m%d-%H%M')}-{secrets.token_hex(2).upper()}"
    return {
        'report_id': report_id,
        'generated_at': now.isoformat(),
        'summary': 'MechOS Companion developer diagnostic bundle',
        'optimization_report': report,
        'notifications': notifications(),
        'games_count': len(compatibility_catalog()),
        'update_progress': update_progress(),
        'logs': {
            'mechos-companion-bridge': _journal('mechos-companion-bridge.service'),
            'radarai': _journal('radarai.service'),
            'mechos-update': _journal('mechos-update.service'),
        },
    }


class Handler(base.Handler):
    server_version = 'MechOSBridge/0.1.2'

    def _token(self):
        auth = self.headers.get('Authorization', '')
        return auth[7:] if auth.startswith('Bearer ') else ''

    def do_GET(self):
        if self.path == '/v1/health':
            return self._json(200, {'ok': True, 'version': '0.1.2'})

        new_paths = {
            '/v1/performance/live',
            '/v1/games/compatibility',
            '/v1/update/progress',
            '/v1/notifications',
            '/v1/devices',
            '/v1/developer/bug-report',
        }
        if self.path not in new_paths:
            return super().do_GET()
        if not self._authorized():
            return self._json(401, {'error': 'Not paired'})
        if self.path == '/v1/performance/live':
            return self._json(200, performance_sample())
        if self.path == '/v1/games/compatibility':
            return self._json(200, {'games': compatibility_catalog()})
        if self.path == '/v1/update/progress':
            return self._json(200, update_progress())
        if self.path == '/v1/notifications':
            return self._json(200, {'notifications': notifications()})
        if self.path == '/v1/devices':
            return self._json(200, {'devices': paired_devices(self._token())})
        if self.path == '/v1/developer/bug-report':
            return self._json(200, developer_bug_report())
        return self._json(404, {'error': 'Not found'})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', default='0.0.0.0')
    parser.add_argument('--port', type=int, default=base.PORT)
    args = parser.parse_args()
    print('MechOS Companion Bridge 0.1.2')
    print(f'Pairing code: {base.PAIR_CODE}')
    print(f'Listening on http://{args.bind}:{args.port}')
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
