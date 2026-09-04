#!/usr/bin/env python3
"""Minimal MechOS Anywhere relay.

Run this behind HTTPS (Caddy/Nginx/load balancer). The PC bridge keeps an
outbound long-poll connection to this relay, which avoids router port
forwarding. Mobile requests are forwarded to the paired PC bridge where the
normal bearer token is still validated.
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import secrets
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

MAX_BODY = 1024 * 1024
REQUEST_TIMEOUT = 45
POLL_TIMEOUT = 25
DEVICES_FILE = Path(os.environ.get('MECHOS_RELAY_DEVICES_FILE', '/etc/mechos-relay/devices.json'))

CONDITION = threading.Condition()
PENDING: dict[str, collections.deque] = collections.defaultdict(collections.deque)
RESPONSES: dict[str, dict] = {}


def load_devices() -> dict[str, str]:
    try:
        data = json.loads(DEVICES_FILE.read_text())
        if isinstance(data, dict):
            return {str(k): str(v) for k, v in data.items() if k and v}
    except Exception:
        pass
    raw = os.environ.get('MECHOS_RELAY_DEVICES_JSON', '')
    if raw:
        try:
            data = json.loads(raw)
            if isinstance(data, dict):
                return {str(k): str(v) for k, v in data.items() if k and v}
        except Exception:
            pass
    return {}


def valid_device(device_id: str) -> bool:
    return device_id in load_devices()


def valid_agent(device_id: str, supplied_secret: str) -> bool:
    expected = load_devices().get(device_id)
    return bool(expected and secrets.compare_digest(expected, supplied_secret or ''))


class Handler(BaseHTTPRequestHandler):
    server_version = 'MechOSRelay/0.2.0'

    def log_message(self, fmt, *args):
        print('[relay]', fmt % args)

    def _json(self, status: int, value: dict):
        body = json.dumps(value).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def _body_bytes(self) -> bytes:
        length = int(self.headers.get('Content-Length', '0') or '0')
        if length < 0 or length > MAX_BODY:
            raise ValueError('Request body is too large')
        return self.rfile.read(length) if length else b''

    def _body_json(self) -> dict:
        raw = self._body_bytes()
        if not raw:
            return {}
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError('JSON object required')
        return value

    def _agent_secret(self) -> str:
        return self.headers.get('X-MechOS-Relay-Secret', '')

    def do_GET(self):
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == '/v1/health':
            return self._json(200, {'ok': True, 'version': '0.2.0'})
        if parsed.path == '/v1/agent/poll':
            return self._poll(parsed)
        if parsed.path.startswith('/device/'):
            return self._device_request('GET', parsed, b'')
        return self._json(404, {'error': 'Not found'})

    def do_POST(self):
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == '/v1/agent/respond':
            return self._respond()
        if parsed.path.startswith('/device/'):
            try:
                body = self._body_bytes()
            except Exception as exc:
                return self._json(400, {'error': str(exc)})
            return self._device_request('POST', parsed, body)
        return self._json(404, {'error': 'Not found'})

    def _poll(self, parsed):
        query = urllib.parse.parse_qs(parsed.query)
        device_id = (query.get('device_id') or [''])[0]
        if not valid_agent(device_id, self._agent_secret()):
            return self._json(401, {'error': 'Invalid relay device credentials'})

        deadline = time.monotonic() + POLL_TIMEOUT
        with CONDITION:
            while not PENDING[device_id]:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    self.send_response(204)
                    self.send_header('Cache-Control', 'no-store')
                    self.end_headers()
                    return
                CONDITION.wait(timeout=remaining)
            request_data = PENDING[device_id].popleft()
        return self._json(200, {'request': request_data})

    def _respond(self):
        try:
            data = self._body_json()
        except Exception as exc:
            return self._json(400, {'error': str(exc)})
        device_id = str(data.get('device_id', ''))
        if not valid_agent(device_id, self._agent_secret()):
            return self._json(401, {'error': 'Invalid relay device credentials'})
        request_id = str(data.get('request_id', ''))
        response = data.get('response')
        if not request_id or not isinstance(response, dict):
            return self._json(400, {'error': 'Invalid relay response'})
        with CONDITION:
            RESPONSES[request_id] = response
            CONDITION.notify_all()
        return self._json(200, {'ok': True})

    def _device_request(self, method: str, parsed, body: bytes):
        parts = parsed.path.split('/', 3)
        if len(parts) < 4:
            return self._json(404, {'error': 'Device route requires an API path'})
        device_id = urllib.parse.unquote(parts[2])
        downstream_path = '/' + parts[3]
        if parsed.query:
            downstream_path += '?' + parsed.query
        if not valid_device(device_id):
            return self._json(404, {'error': 'Unknown MechOS device'})
        if not downstream_path.startswith('/v1/'):
            return self._json(400, {'error': 'Only MechOS Companion API routes are allowed'})

        request_id = secrets.token_hex(12)
        request_data = {
            'id': request_id,
            'method': method,
            'path': downstream_path,
            'authorization': self.headers.get('Authorization', ''),
            'body': body.decode(errors='replace') if body else '',
        }
        with CONDITION:
            PENDING[device_id].append(request_data)
            CONDITION.notify_all()

            deadline = time.monotonic() + REQUEST_TIMEOUT
            while request_id not in RESPONSES:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    return self._json(504, {'error': 'MechOS PC did not answer the relay in time'})
                CONDITION.wait(timeout=remaining)
            response = RESPONSES.pop(request_id)

        status = int(response.get('status', 502))
        raw = str(response.get('body', '')).encode()
        content_type = str(response.get('content_type', 'application/json'))
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(raw)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(raw)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--bind', default='127.0.0.1')
    parser.add_argument('--port', type=int, default=47832)
    args = parser.parse_args()
    devices = load_devices()
    if not devices:
        print('WARNING: no MechOS relay devices are configured.')
    print(f'MechOS Anywhere Relay 0.2.0 listening on http://{args.bind}:{args.port}')
    print('Use an HTTPS reverse proxy before exposing this service to the internet.')
    ThreadingHTTPServer((args.bind, args.port), Handler).serve_forever()


if __name__ == '__main__':
    main()
