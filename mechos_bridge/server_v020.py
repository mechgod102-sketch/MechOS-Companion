#!/usr/bin/env python3
"""MechOS Companion Bridge 0.2.0.

Adds the Unified/Creator Store, remote install queue, and the optional
MechOS Anywhere outbound relay agent while preserving the 0.1.1 bridge API.
"""
from __future__ import annotations

import json
import os
import secrets
import shutil
import socket
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
from http.server import ThreadingHTTPServer

import server as legacy

VERSION = '0.2.0'

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


def _remote_device_url() -> str | None:
    relay = os.environ.get('MECHOS_RELAY_PUBLIC_URL') or os.environ.get('MECHOS_RELAY_URL')
    device_id = os.environ.get('MECHOS_RELAY_DEVICE_ID')
    if not relay or not device_id:
        return None
    encoded = urllib.parse.quote(device_id, safe='')
    return f"{relay.rstrip('/')}/device/{encoded}"


class Handler(legacy.Handler):
    server_version = 'MechOSBridge/0.2.0'

    def do_GET(self):
        path = urllib.parse.urlsplit(self.path).path
        if path == '/v1/health':
            return self._json(200, {'ok': True, 'version': VERSION})
        if path in ('/v1/store/catalog', '/v1/store/downloads'):
            if not self._authorized():
                return self._json(401, {'error': 'Not paired'})
            if path == '/v1/store/catalog':
                return self._json(200, {'items': [_catalog_item(item) for item in STORE_ITEMS]})
            return self._json(200, {'downloads': _downloads()})
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

        if path == '/v1/store/install':
            if not self._authorized():
                return self._json(401, {'error': 'Not paired'})
            try:
                data = self._body()
                task = _queue_install(str(data.get('item_id', '')))
            except KeyError:
                return self._json(404, {'error': 'Store item not found'})
            except Exception as exc:
                return self._json(400, {'error': str(exc)})
            return self._json(202, {'download': task})

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
    remote_url = _remote_device_url()
    if remote_url:
        print(f'MechOS Anywhere URL: {remote_url}')
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
