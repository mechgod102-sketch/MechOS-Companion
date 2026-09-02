#!/usr/bin/env python3
"""MechOS Companion Bridge 0.1.1: authenticated local-LAN API."""
from __future__ import annotations

import argparse
import json
import os
import platform
import secrets
import shutil
import socket
import subprocess
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 47831
CONFIG = Path.home() / '.config' / 'mechos-companion-bridge'
TOKENS = CONFIG / 'devices.json'
ALERTS = Path.home() / '.local' / 'state' / 'radarai' / 'alerts.json'
PAIR_CODE = f'{secrets.randbelow(1_000_000):06d}'

ACTIONS = {
    'session:mechscope': ['mechos-session-select', '--mechscope'],
    'session:desktop': ['mechos-session-select', '--desktop'],
    'update_check': ['mechos-update', '--check'],
    'update_install': ['mechos-update', '--install'],
    'radarai_scan': ['radarai', 'scan', '--quick'],
    'restart': ['mechos-power-control', '--restart'],
    'shutdown': ['mechos-power-control', '--shutdown'],
}


def _load_tokens():
    try:
        value = json.loads(TOKENS.read_text())
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}


def _save_tokens(value):
    CONFIG.mkdir(parents=True, exist_ok=True)
    TOKENS.write_text(json.dumps(value, indent=2))
    os.chmod(TOKENS, 0o600)


def run(cmd, timeout=25):
    """Run only a fixed command list supplied by this bridge, never user shell text."""
    exe = shutil.which(cmd[0])
    if not exe:
        return False, f'MechOS integration missing: {cmd[0]}'
    try:
        p = subprocess.run([exe, *cmd[1:]], text=True, capture_output=True,
                           timeout=timeout, check=False)
        msg = (p.stdout or p.stderr or '').strip()
        if not msg:
            msg = 'Completed' if p.returncode == 0 else f'Failed ({p.returncode})'
        return p.returncode == 0, msg
    except Exception as exc:
        return False, str(exc)


def _os_info():
    data = {}
    try:
        for line in Path('/etc/os-release').read_text().splitlines():
            if '=' in line:
                key, value = line.split('=', 1)
                data[key] = value.strip('"')
    except Exception:
        pass
    return data


def _meminfo():
    total = available = 0
    try:
        for line in Path('/proc/meminfo').read_text().splitlines():
            if line.startswith('MemTotal:'):
                total = int(line.split()[1]) * 1024
            elif line.startswith('MemAvailable:'):
                available = int(line.split()[1]) * 1024
    except Exception:
        pass
    return (total - available) / 2**30, total / 2**30


def _diskinfo():
    d = shutil.disk_usage('/')
    return (d.total - d.free) / 2**30, d.total / 2**30


def _cpu_name():
    try:
        for line in Path('/proc/cpuinfo').read_text(errors='ignore').splitlines():
            if line.lower().startswith(('model name', 'hardware')) and ':' in line:
                return line.split(':', 1)[1].strip()
    except Exception:
        pass
    return platform.processor() or 'Unknown CPU'


def _gpu_name():
    ok, text = run(['lspci'], 4)
    if ok:
        for line in text.splitlines():
            low = line.lower()
            if 'vga compatible controller' in low or '3d controller' in low or 'display controller' in low:
                return line.split(': ', 1)[-1].strip()
    return 'Unknown GPU'


def _cpu_sample():
    try:
        values = [int(x) for x in Path('/proc/stat').read_text().splitlines()[0].split()[1:]]
        idle = values[3] + (values[4] if len(values) > 4 else 0)
        return sum(values), idle
    except Exception:
        return 0, 0


def cpu_percent(delay=0.12):
    total1, idle1 = _cpu_sample()
    time.sleep(delay)
    total2, idle2 = _cpu_sample()
    delta = total2 - total1
    if delta <= 0:
        return 0.0
    value = 100 * (1 - ((idle2 - idle1) / delta))
    return round(max(0.0, min(100.0, value)), 1)


def gpu_percent():
    nvidia = shutil.which('nvidia-smi')
    if nvidia:
        try:
            p = subprocess.run(
                [nvidia, '--query-gpu=utilization.gpu', '--format=csv,noheader,nounits'],
                text=True, capture_output=True, timeout=3, check=False)
            values = [float(v.strip()) for v in p.stdout.splitlines() if v.strip()]
            if values:
                return round(max(0.0, min(100.0, max(values))), 1)
        except Exception:
            pass
    # AMD/Intel DRM drivers may expose gpu_busy_percent.
    for path in sorted(Path('/sys/class/drm').glob('card*/device/gpu_busy_percent')):
        try:
            value = float(path.read_text().strip())
            if 0 <= value <= 100:
                return round(value, 1)
        except Exception:
            pass
    return None


def temperature_c():
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


def build_channel(info=None):
    if os.environ.get('MECHOS_CHANNEL'):
        return os.environ['MECHOS_CHANNEL']
    for path in [Path('/etc/mechos-channel'), Path('/etc/mechos/channel')]:
        try:
            value = path.read_text().strip()
            if value:
                return value
        except Exception:
            pass
    text = ((info or _os_info()).get('PRETTY_NAME') or '').lower()
    if 'dev' in text:
        return 'Dev'
    if 'beta' in text:
        return 'Beta'
    return 'Stable'


def update_state():
    ok, msg = run(['mechos-update', '--check'], 8)
    if not ok:
        return False, msg
    low = msg.lower()
    if any(x in low for x in ['no update', 'no updates', 'up to date', 'up-to-date', 'nothing to do']):
        return False, msg
    return any(x in low for x in ['available', 'upgrade', 'update']), msg


def radar_state():
    ok, msg = run(['radarai', 'status'], 5)
    if not ok:
        return 'Unavailable'
    return msg.splitlines()[0] if msg else 'Healthy'


def alerts():
    try:
        raw = json.loads(ALERTS.read_text())
        if isinstance(raw, list):
            return raw
        if isinstance(raw, dict):
            return raw.get('alerts', [])
    except Exception:
        pass
    return []


def base_status():
    ram_used, ram_total = _meminfo()
    disk_used, disk_total = _diskinfo()
    info = _os_info()
    available, _ = update_state()
    return {
        'hostname': socket.gethostname(),
        'os_version': info.get('PRETTY_NAME', 'MechOS'),
        'build_channel': build_channel(info),
        'kernel': platform.release(),
        'cpu': _cpu_name(),
        'gpu': _gpu_name(),
        'ram_used_gb': round(ram_used, 1),
        'ram_total_gb': round(ram_total, 1),
        'storage_used_gb': round(disk_used, 1),
        'storage_total_gb': round(disk_total, 1),
        'session': os.environ.get('XDG_CURRENT_DESKTOP') or os.environ.get('XDG_SESSION_DESKTOP') or 'Unknown',
        'update_available': available,
        'radarai_state': radar_state(),
    }


def status():
    return base_status()


def _finding(severity, title, detail):
    return {'severity': severity, 'title': title, 'detail': detail}


def optimization_report():
    s = base_status()
    cpu = cpu_percent()
    gpu = gpu_percent()
    temp = temperature_c()
    ram_pct = 0 if s['ram_total_gb'] <= 0 else s['ram_used_gb'] / s['ram_total_gb'] * 100
    disk_pct = 0 if s['storage_total_gb'] <= 0 else s['storage_used_gb'] / s['storage_total_gb'] * 100
    findings, fixes = [], []
    score = 100

    if cpu >= 90:
        findings.append(_finding('critical', 'Very high CPU load', 'CPU load was above 90% during the scan.'))
        fixes.append('Close unnecessary background applications before gaming or streaming.')
        score -= 15
    elif cpu >= 75:
        findings.append(_finding('warning', 'High background CPU usage', 'CPU load was elevated during the scan.'))
        fixes.append('Review background processes and close unneeded applications.')
        score -= 8

    if gpu is not None and gpu >= 98:
        findings.append(_finding('warning', 'GPU fully utilized', 'GPU utilization was near its maximum during the scan.'))
        fixes.append('Review game graphics settings or frame caps if performance is unstable.')
        score -= 6

    if ram_pct >= 92:
        findings.append(_finding('critical', 'Memory pressure is high', 'More than 92% of system memory is in use.'))
        fixes.append('Close memory-heavy background applications before demanding workloads.')
        score -= 18
    elif ram_pct >= 82:
        findings.append(_finding('warning', 'Memory usage is elevated', 'Memory usage is above 82%.'))
        fixes.append('Free memory before launching demanding games or creator workloads.')
        score -= 8

    if disk_pct >= 92:
        findings.append(_finding('critical', 'Storage is nearly full', 'The system drive has less than about 8% free space.'))
        fixes.append('Free storage space before installing updates or large game content.')
        score -= 20
    elif disk_pct >= 80:
        findings.append(_finding('warning', 'Low free storage', 'The system drive is above 80% used.'))
        fixes.append('Keep roughly 20% of storage free for updates, shader caches, and temporary files.')
        score -= 10

    if temp is not None and temp >= 95:
        findings.append(_finding('critical', 'High system temperature', f'A detected sensor reached {temp:.0f}°C.'))
        fixes.append('Check cooling and airflow before continuing a heavy workload.')
        score -= 20
    elif temp is not None and temp >= 85:
        findings.append(_finding('warning', 'System temperature is elevated', f'A detected sensor reached {temp:.0f}°C.'))
        fixes.append('Review cooling and airflow if elevated temperatures continue.')
        score -= 10

    if s['update_available']:
        findings.append(_finding('info', 'MechOS update available', 'A system update is available for review.'))
        fixes.append('Review the available MechOS update before installing it.')
        score -= 3

    if 'unavailable' in s['radarai_state'].lower():
        findings.append(_finding('warning', 'RadarAI unavailable', 'The bridge could not read RadarAI health status.'))
        fixes.append('Check that RadarAI is installed and its user service is running.')
        score -= 5

    for alert in alerts()[:4]:
        if not isinstance(alert, dict):
            continue
        severity = str(alert.get('severity', 'info')).lower()
        findings.append(_finding(severity, str(alert.get('title', 'RadarAI alert'))[:120], str(alert.get('detail', 'RadarAI reported a system condition.'))[:240]))
        score -= 12 if severity in ('critical', 'error') else 5 if severity == 'warning' else 0

    if not findings:
        findings.append(_finding('info', 'No major optimization issues detected', 'The current scan did not find a high-priority optimization warning.'))
    if not fixes:
        fixes.append('No immediate optimization action is required; continue monitoring during normal use.')

    now = datetime.now(timezone.utc)
    return {
        'report_id': f"MCHS-{now.strftime('%Y%m%d-%H%M')}-{secrets.token_hex(2).upper()}",
        'generated_at': now.isoformat(),
        'hostname': s['hostname'],
        'os_version': s['os_version'],
        'build_channel': s['build_channel'],
        'session': s['session'],
        'radarai_state': s['radarai_state'],
        'score': max(0, min(100, score)),
        'update_available': s['update_available'],
        'metrics': {
            'cpu_percent': round(cpu, 1),
            'gpu_percent': gpu,
            'ram_percent': round(ram_pct, 1),
            'storage_percent': round(disk_pct, 1),
            'temperature_c': temp,
        },
        'hardware': {
            'cpu': s['cpu'],
            'gpu': s['gpu'],
            'ram_used_gb': s['ram_used_gb'],
            'ram_total_gb': s['ram_total_gb'],
            'storage_used_gb': s['storage_used_gb'],
            'storage_total_gb': s['storage_total_gb'],
        },
        'findings': findings[:8],
        'recommended_fixes': list(dict.fromkeys(fixes))[:8],
    }


class Handler(BaseHTTPRequestHandler):
    server_version = 'MechOSBridge/0.1.1'

    def log_message(self, fmt, *args):
        print('[bridge]', fmt % args)

    def _json(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        length = int(self.headers.get('Content-Length', '0'))
        return json.loads(self.rfile.read(length) or b'{}')

    def _authorized(self):
        auth = self.headers.get('Authorization', '')
        token = auth[7:] if auth.startswith('Bearer ') else ''
        return bool(token and token in _load_tokens())

    def do_GET(self):
        if self.path == '/v1/health':
            return self._json(200, {'ok': True, 'version': '0.1.1'})
        if not self._authorized():
            return self._json(401, {'error': 'Not paired'})
        if self.path == '/v1/status':
            return self._json(200, status())
        if self.path == '/v1/radarai/alerts':
            return self._json(200, {'alerts': alerts()})
        if self.path == '/v1/optimization/report':
            return self._json(200, optimization_report())
        return self._json(404, {'error': 'Not found'})

    def do_POST(self):
        try:
            data = self._body()
        except Exception:
            return self._json(400, {'error': 'Invalid JSON'})
        if self.path == '/v1/pair':
            if str(data.get('code', '')) != PAIR_CODE:
                return self._json(403, {'error': 'Invalid pairing code'})
            token = secrets.token_urlsafe(32)
            devices = _load_tokens()
            devices[token] = {'name': str(data.get('device_name', 'Mobile'))[:80], 'paired_at': int(time.time())}
            _save_tokens(devices)
            return self._json(200, {'token': token, 'mechos_name': socket.gethostname()})
        if not self._authorized():
            return self._json(401, {'error': 'Not paired'})
        if self.path == '/v1/action':
            action = str(data.get('action', ''))
            value = str(data.get('value', ''))
            key = f'{action}:{value}' if action == 'session' else action
            cmd = ACTIONS.get(key)
            if not cmd:
                return self._json(400, {'error': 'Action is not allowed'})
            ok, msg = run(cmd, 90 if action == 'update_install' else 30)
            return self._json(200 if ok else 503, {'ok': ok, 'message': msg})
        return self._json(404, {'error': 'Not found'})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', default='0.0.0.0')
    parser.add_argument('--port', type=int, default=PORT)
    args = parser.parse_args()
    print('MechOS Companion Bridge 0.1.1')
    print(f'Pairing code: {PAIR_CODE}')
    print(f'Listening on http://{args.bind}:{args.port}')
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
