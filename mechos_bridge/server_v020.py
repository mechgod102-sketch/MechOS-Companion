#!/usr/bin/env python3
"""MechOS Companion Bridge 0.2.1.

Adds Unified/Creator Store installs, MechOS Anywhere relay support, remote
screen frames, and validated remote input while preserving the legacy API.
"""
from __future__ import annotations

import base64
import json
import os
import secrets
import shutil
import socket
import subprocess
import tempfile
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from http.server import ThreadingHTTPServer
from pathlib import Path

import server as legacy

VERSION = '0.2.1'

# Extend the legacy fixed action allow-list. These still execute only known
# MechOS helper commands; mobile clients cannot provide executable text.
legacy.ACTIONS.update({
    'lock': ['mechos-power-control', '--lock'],
    'sleep': ['mechos-power-control', '--sleep'],
})

STORE_ITEMS = [
    {
        'id': 'steam',
        'name': 'Steam',
        'description': 'Game library and launcher.',
        'category': 'Games',
        'creator': False,
        'flatpak_id': 'com.valvesoftware.Steam',
    },
    {
        'id': 'discord',
        'name': 'Discord',
        'description': 'Voice, chat, and community app.',
        'category': 'Communication',
        'creator': False,
        'flatpak_id': 'com.discordapp.Discord',
    },
    {
        'id': 'obs',
        'name': 'OBS Studio',
        'description': 'Streaming and recording suite.',
        'category': 'Streaming',
        'creator': True,
        'flatpak_id': 'com.obsproject.Studio',
    },
    {
        'id': 'blender',
        'name': 'Blender',
        'description': '3D modeling, animation, and rendering.',
        'category': '3D & Modeling',
        'creator': True,
        'flatpak_id': 'org.blender.Blender',
    },
    {
        'id': 'godot',
        'name': 'Godot Engine',
        'description': 'Open-source game development engine.',
        'category': 'Game Engines',
        'creator': True,
        'flatpak_id': 'org.godotengine.Godot',
    },
    {
        'id': 'krita',
        'name': 'Krita',
        'description': 'Digital painting and texture creation.',
        'category': 'Art & Design',
        'creator': True,
        'flatpak_id': 'org.kde.krita',
    },
    {
        'id': 'kdenlive',
        'name': 'Kdenlive',
        'description': 'Non-linear video editing for creator workflows.',
        'category': 'Video',
        'creator': True,
        'flatpak_id': 'org.kde.kdenlive',
    },
    {
        'id': 'gimp',
        'name': 'GIMP',
        'description': 'Image editing and texture preparation.',
        'category': 'Art & Design',
        'creator': True,
        'flatpak_id': 'org.gimp.GIMP',
    },
]
STORE_BY_ID = {item['id']: item for item in STORE_ITEMS}
DOWNLOADS: dict[str, dict] = {}
DOWNLOAD_LOCK = threading.Lock()
REMOTE_FRAME_LOCK = threading.Lock()
LAST_FRAME_SIZE = [1920, 1080]


def _catalog_item(item: dict) -> dict:
    return {
        'id': item['id'],
        'name': item['name'],
        'description': item['description'],
        'category': item['category'],
        'creator': item['creator'],
        'installable': bool(shutil.which('mechos-store-cli') or shutil.which('flatpak')),
    }


def _downloads() -> list[dict]:
    with DOWNLOAD_LOCK:
        items = [dict(value) for value in DOWNLOADS.values()]
    items.sort(key=lambda value: value.get('created_at', 0), reverse=True)
    for item in items:
        item.pop('created_at', None)
    return items[:30]


def _set_download(task_id: str, **changes) -> None:
    with DOWNLOAD_LOCK:
        if task_id in DOWNLOADS:
            DOWNLOADS[task_id].update(changes)


def _install_worker(task_id: str, item: dict) -> None:
    _set_download(task_id, state='installing', progress=10, message='Preparing install on MechOS PC')
    if shutil.which('mechos-store-cli'):
        cmd = ['mechos-store-cli', 'install', '--non-interactive', item['id']]
    elif shutil.which('flatpak') and item.get('flatpak_id'):
        cmd = ['flatpak', 'install', '--user', '-y', 'flathub', item['flatpak_id']]
    else:
        _set_download(
            task_id,
            state='failed',
            progress=0,
            message='No supported MechOS store installer is available on this PC.',
        )
        return

    _set_download(task_id, progress=35, message='Downloading and installing')
    ok, message = legacy.run(cmd, 1800)
    _set_download(
        task_id,
        state='installed' if ok else 'failed',
        progress=100 if ok else 35,
        message=message[:500],
    )


def _queue_install(item_id: str) -> dict:
    item = STORE_BY_ID.get(item_id)
    if item is None:
        raise KeyError('Unknown store item')
    task_id = secrets.token_hex(8)
    task = {
        'id': task_id,
        'item_id': item['id'],
        'name': item['name'],
        'state': 'queued',
        'progress': 0,
        'message': 'Queued for remote install',
        'created_at': time.time(),
    }
    with DOWNLOAD_LOCK:
        DOWNLOADS[task_id] = task
    threading.Thread(target=_install_worker, args=(task_id, item), daemon=True).start()
    result = dict(task)
    result.pop('created_at', None)
    return result


def _image_size(data: bytes) -> tuple[int, int]:
    if data.startswith(b'\x89PNG\r\n\x1a\n') and len(data) >= 24:
        return (
            int.from_bytes(data[16:20], 'big'),
            int.from_bytes(data[20:24], 'big'),
        )
    if data.startswith(b'\xff\xd8'):
        i = 2
        sof = {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF}
        while i + 9 < len(data):
            if data[i] != 0xFF:
                i += 1
                continue
            while i < len(data) and data[i] == 0xFF:
                i += 1
            if i >= len(data):
                break
            marker = data[i]
            i += 1
            if marker in (0xD8, 0xD9):
                continue
            if i + 2 > len(data):
                break
            length = int.from_bytes(data[i:i + 2], 'big')
            if length < 2 or i + length > len(data):
                break
            if marker in sof and length >= 7:
                height = int.from_bytes(data[i + 3:i + 5], 'big')
                width = int.from_bytes(data[i + 5:i + 7], 'big')
                return width, height
            i += length
    return LAST_FRAME_SIZE[0], LAST_FRAME_SIZE[1]


def _capture_command(path: str, quality: int) -> list[str] | None:
    if shutil.which('grim'):
        return ['grim', '-t', 'jpeg', '-q', str(quality), path]
    if shutil.which('spectacle'):
        return ['spectacle', '-b', '-n', '-o', path]
    if shutil.which('gnome-screenshot'):
        return ['gnome-screenshot', '-f', path]
    if shutil.which('scrot'):
        return ['scrot', path]
    return None


def _capture_frame(quality: int) -> dict:
    quality = max(30, min(80, int(quality)))
    with REMOTE_FRAME_LOCK:
        jpeg = bool(shutil.which('grim'))
        suffix = '.jpg' if jpeg else '.png'
        temp = tempfile.NamedTemporaryFile(prefix='mechos-remote-', suffix=suffix, delete=False)
        path = temp.name
        temp.close()
        try:
            cmd = _capture_command(path, quality)
            if cmd is None:
                raise RuntimeError('Screen capture support missing. Install grim, Spectacle, gnome-screenshot, or scrot.')
            p = subprocess.run(cmd, text=True, capture_output=True, timeout=10, check=False)
            if p.returncode != 0:
                message = (p.stderr or p.stdout or 'screen capture failed').strip()
                raise RuntimeError(message[:300])
            data = Path(path).read_bytes()
            if not data:
                raise RuntimeError('Screen capture returned an empty frame.')
            if len(data) > 7 * 1024 * 1024:
                raise RuntimeError('Screen frame is too large for remote streaming. Use grim/JPEG capture on this PC.')
            width, height = _image_size(data)
            LAST_FRAME_SIZE[0] = max(1, width)
            LAST_FRAME_SIZE[1] = max(1, height)
            return {
                'image_base64': base64.b64encode(data).decode('ascii'),
                'width': LAST_FRAME_SIZE[0],
                'height': LAST_FRAME_SIZE[1],
                'captured_at': datetime.now(timezone.utc).isoformat(),
            }
        finally:
            try:
                os.unlink(path)
            except OSError:
                pass


def _normalized(value, name: str) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f'Invalid {name}') from exc
    if not 0 <= number <= 1:
        raise ValueError(f'{name} must be between 0 and 1')
    return number


def _run_input(cmd: list[str], *, text_input: str | None = None) -> str:
    exe = shutil.which(cmd[0])
    if not exe:
        raise RuntimeError(f'Remote input support missing: {cmd[0]}')
    p = subprocess.run(
        [exe, *cmd[1:]],
        input=text_input,
        text=True,
        capture_output=True,
        timeout=6,
        check=False,
    )
    if p.returncode != 0:
        message = (p.stderr or p.stdout or f'{cmd[0]} failed').strip()
        raise RuntimeError(message[:300])
    return (p.stdout or '').strip()


def _pointer_move(x: int, y: int) -> None:
    if shutil.which('ydotool'):
        _run_input(['ydotool', 'mousemove', '--absolute', str(x), str(y)])
        return
    if shutil.which('xdotool'):
        _run_input(['xdotool', 'mousemove', str(x), str(y)])
        return
    raise RuntimeError('Remote input support missing. Install ydotool (Wayland) or xdotool (X11).')


def _mouse_click(button: str) -> None:
    if button not in ('left', 'right'):
        raise ValueError('Unsupported mouse button')
    if shutil.which('ydotool'):
        _run_input(['ydotool', 'click', '0xC0' if button == 'left' else '0xC1'])
        return
    if shutil.which('xdotool'):
        _run_input(['xdotool', 'click', '1' if button == 'left' else '3'])
        return
    raise RuntimeError('Remote input support missing. Install ydotool (Wayland) or xdotool (X11).')


def _remote_key(name: str) -> None:
    xkeys = {
        'escape': 'Escape',
        'enter': 'Return',
        'tab': 'Tab',
        'backspace': 'BackSpace',
        'up': 'Up',
        'down': 'Down',
        'left': 'Left',
        'right': 'Right',
        'alt_tab': 'alt+Tab',
    }
    ykeys = {
        'escape': ['1:1', '1:0'],
        'enter': ['28:1', '28:0'],
        'tab': ['15:1', '15:0'],
        'backspace': ['14:1', '14:0'],
        'up': ['103:1', '103:0'],
        'down': ['108:1', '108:0'],
        'left': ['105:1', '105:0'],
        'right': ['106:1', '106:0'],
        'alt_tab': ['56:1', '15:1', '15:0', '56:0'],
    }
    if name not in xkeys:
        raise ValueError('Unsupported remote key')
    if shutil.which('ydotool'):
        _run_input(['ydotool', 'key', *ykeys[name]])
        return
    if shutil.which('xdotool'):
        _run_input(['xdotool', 'key', xkeys[name]])
        return
    raise RuntimeError('Remote input support missing. Install ydotool (Wayland) or xdotool (X11).')


def _remote_text(text: str) -> None:
    if len(text) > 500:
        raise ValueError('Remote text is limited to 500 characters')
    if '\x00' in text:
        raise ValueError('Invalid remote text')
    if shutil.which('ydotool'):
        _run_input(['ydotool', 'type', '--file', '-'], text_input=text)
        return
    if shutil.which('xdotool'):
        _run_input(['xdotool', 'type', '--clearmodifiers', '--delay', '1', '--', text])
        return
    raise RuntimeError('Remote input support missing. Install ydotool (Wayland) or xdotool (X11).')


def _remote_scroll(delta: int) -> None:
    delta = max(-10, min(10, int(delta)))
    if delta == 0:
        return
    if shutil.which('xdotool'):
        button = '4' if delta > 0 else '5'
        for _ in range(abs(delta)):
            _run_input(['xdotool', 'click', button])
        return
    if shutil.which('ydotool'):
        _run_input(['ydotool', 'mousemove', '--wheel', '--', '0', str(delta)])
        return
    raise RuntimeError('Remote input support missing. Install ydotool (Wayland) or xdotool (X11).')


def _handle_remote_input(data: dict) -> None:
    kind = str(data.get('type', ''))
    if kind == 'tap':
        x = _normalized(data.get('x'), 'x')
        y = _normalized(data.get('y'), 'y')
        px = round(x * max(0, LAST_FRAME_SIZE[0] - 1))
        py = round(y * max(0, LAST_FRAME_SIZE[1] - 1))
        _pointer_move(px, py)
        _mouse_click('left')
        return
    if kind == 'click':
        _mouse_click(str(data.get('key', 'left')))
        return
    if kind == 'scroll':
        _remote_scroll(int(float(data.get('delta', 0))))
        return
    if kind == 'key':
        _remote_key(str(data.get('key', '')))
        return
    if kind == 'text':
        _remote_text(str(data.get('text', '')))
        return
    raise ValueError('Unsupported remote input type')


def _remote_device_url() -> str | None:
    relay = os.environ.get('MECHOS_RELAY_PUBLIC_URL') or os.environ.get('MECHOS_RELAY_URL')
    device_id = os.environ.get('MECHOS_RELAY_DEVICE_ID')
    if not relay or not device_id:
        return None
    encoded = urllib.parse.quote(device_id, safe='')
    return f"{relay.rstrip('/')}/device/{encoded}"


class Handler(legacy.Handler):
    server_version = 'MechOSBridge/0.2.1'

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        path = parsed.path
        if path == '/v1/health':
            return self._json(200, {'ok': True, 'version': VERSION})
        if path in ('/v1/store/catalog', '/v1/store/downloads', '/v1/remote/frame'):
            if not self._authorized():
                return self._json(401, {'error': 'Not paired'})
            if path == '/v1/store/catalog':
                return self._json(200, {'items': [_catalog_item(item) for item in STORE_ITEMS]})
            if path == '/v1/store/downloads':
                return self._json(200, {'downloads': _downloads()})
            try:
                query = urllib.parse.parse_qs(parsed.query)
                quality = int(query.get('quality', ['55'])[0])
                return self._json(200, _capture_frame(quality))
            except Exception as exc:
                return self._json(503, {'error': str(exc)})
        return super().do_GET()

    def do_POST(self):
        path = urllib.parse.urlsplit(self.path).path
        if path == '/v1/pair':
            try:
                data = self._body()
            except Exception:
                return self._json(400, {'error': 'Invalid JSON'})
            if str(data.get('code', '')) != legacy.PAIR_CODE:
                return self._json(403, {'error': 'Invalid pairing code'})
            token = secrets.token_urlsafe(32)
            devices = legacy._load_tokens()
            devices[token] = {
                'name': str(data.get('device_name', 'Mobile'))[:80],
                'paired_at': int(time.time()),
            }
            legacy._save_tokens(devices)
            payload = {
                'token': token,
                'mechos_name': socket.gethostname(),
            }
            remote_url = _remote_device_url()
            if remote_url:
                payload['remote_url'] = remote_url
            return self._json(200, payload)

        if path in ('/v1/store/install', '/v1/remote/input'):
            if not self._authorized():
                return self._json(401, {'error': 'Not paired'})
            try:
                data = self._body()
                if path == '/v1/store/install':
                    task = _queue_install(str(data.get('item_id', '')))
                    return self._json(202, {'download': task})
                _handle_remote_input(data)
                return self._json(200, {'ok': True})
            except KeyError:
                return self._json(404, {'error': 'Store item not found'})
            except ValueError as exc:
                return self._json(400, {'error': str(exc)})
            except Exception as exc:
                return self._json(503, {'error': str(exc)})

        return super().do_POST()


class RelayAgent(threading.Thread):
    """Long-poll relay client for PCs behind NAT.

    The relay is expected to be HTTPS in production. The normal bridge bearer
    token still authorizes every forwarded mobile request at the PC.
    """

    daemon = True

    def __init__(self, relay_url: str, device_id: str, secret: str, port: int):
        super().__init__(name='mechos-anywhere-relay')
        self.relay_url = relay_url.rstrip('/')
        self.device_id = device_id
        self.secret = secret
        self.port = port

    def run(self) -> None:
        print(f'[relay] MechOS Anywhere enabled for device {self.device_id}')
        while True:
            try:
                request_data = self._poll()
                if request_data:
                    response = self._forward(request_data)
                    self._respond(request_data['id'], response)
            except Exception as exc:
                print(f'[relay] {exc}')
                time.sleep(3)

    def _request(self, url: str, *, method='GET', body: bytes | None = None, headers=None, timeout=30):
        request_headers = {'X-MechOS-Relay-Secret': self.secret}
        if headers:
            request_headers.update(headers)
        req = urllib.request.Request(url, data=body, headers=request_headers, method=method)
        return urllib.request.urlopen(req, timeout=timeout)

    def _poll(self) -> dict | None:
        query = urllib.parse.urlencode({'device_id': self.device_id})
        url = f'{self.relay_url}/v1/agent/poll?{query}'
        try:
            with self._request(url, timeout=35) as response:
                if response.status == 204:
                    return None
                payload = json.loads(response.read().decode() or '{}')
                return payload.get('request')
        except urllib.error.HTTPError as exc:
            if exc.code == 204:
                return None
            raise RuntimeError(f'relay poll returned HTTP {exc.code}') from exc

    def _forward(self, request_data: dict) -> dict:
        method = str(request_data.get('method', 'GET')).upper()
        path = str(request_data.get('path', '/v1/health'))
        if method not in ('GET', 'POST') or not path.startswith('/v1/'):
            return {'status': 400, 'body': json.dumps({'error': 'Relay request rejected'})}

        raw_body = request_data.get('body')
        body = raw_body.encode() if isinstance(raw_body, str) and raw_body else None
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
        auth = request_data.get('authorization')
        if auth:
            headers['Authorization'] = str(auth)
        local_url = f'http://127.0.0.1:{self.port}{path}'
        req = urllib.request.Request(local_url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                return {
                    'status': response.status,
                    'content_type': response.headers.get('Content-Type', 'application/json'),
                    'body': response.read().decode(),
                }
        except urllib.error.HTTPError as exc:
            return {
                'status': exc.code,
                'content_type': exc.headers.get('Content-Type', 'application/json'),
                'body': exc.read().decode(),
            }
        except Exception as exc:
            return {
                'status': 503,
                'content_type': 'application/json',
                'body': json.dumps({'error': f'PC bridge unavailable: {exc}'}),
            }

    def _respond(self, request_id: str, response: dict) -> None:
        url = f'{self.relay_url}/v1/agent/respond'
        payload = json.dumps({
            'device_id': self.device_id,
            'request_id': request_id,
            'response': response,
        }).encode()
        with self._request(
            url,
            method='POST',
            body=payload,
            headers={'Content-Type': 'application/json'},
            timeout=15,
        ):
            pass


def main():
    parser = legacy.argparse.ArgumentParser()
    parser.add_argument('--bind', default='0.0.0.0')
    parser.add_argument('--port', type=int, default=legacy.PORT)
    args = parser.parse_args()

    relay_url = os.environ.get('MECHOS_RELAY_URL')
    relay_id = os.environ.get('MECHOS_RELAY_DEVICE_ID')
    relay_secret = os.environ.get('MECHOS_RELAY_SECRET')
    if relay_url and relay_id and relay_secret:
        RelayAgent(relay_url, relay_id, relay_secret, args.port).start()

    print(f'MechOS Companion Bridge {VERSION}')
    print(f'Pairing code: {legacy.PAIR_CODE}')
    print(f'Listening on http://{args.bind}:{args.port}')
    print('Remote Control capture:', 'available' if any(shutil.which(x) for x in ('grim', 'spectacle', 'gnome-screenshot', 'scrot')) else 'missing capture tool')
    print('Remote Control input:', 'available' if any(shutil.which(x) for x in ('ydotool', 'xdotool')) else 'missing input tool')
    remote_url = _remote_device_url()
    if remote_url:
        print(f'MechOS Anywhere URL: {remote_url}')
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
