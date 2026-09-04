#!/usr/bin/env python3
from pathlib import Path
import ast

root = Path(__file__).resolve().parents[1]
required = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/app_state.dart',
    'lib/models/optimization_report.dart',
    'lib/models/discovered_device.dart',
    'lib/models/store_item.dart',
    'lib/models/download_task.dart',
    'lib/services/api_client.dart',
    'lib/services/device_discovery_service.dart',
    'lib/services/report_image_service.dart',
    'lib/services/report_share_service.dart',
    'lib/screens/optimization_report_screen.dart',
    'lib/screens/store_screen.dart',
    'lib/screens/tools_screen.dart',
    'mechos_bridge/server.py',
    'mechos_bridge/server_v020.py',
    'mechos_bridge/mechos-companion.avahi.service',
    'mechos_relay/server.py',
    'scripts/bootstrap-platforms.sh',
    'scripts/apply_platform_patches.py',
    'test/optimization_report_test.dart',
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit('Missing: ' + ', '.join(missing))

for path in [
    'mechos_bridge/server.py',
    'mechos_bridge/server_v020.py',
    'mechos_relay/server.py',
    'scripts/apply_platform_patches.py',
]:
    ast.parse((root / path).read_text())

pubspec = (root / 'pubspec.yaml').read_text()
for dep in [
    'http: ^1.6.0',
    'flutter_secure_storage: ^10.2.0',
    'shared_preferences: ^2.5.5',
    'path_provider: ^2.1.5',
    'share_plus: ^13.3.0',
    'gal: ^2.3.2',
    'multicast_dns: ^0.3.3',
]:
    assert dep in pubspec, dep
assert 'version: 0.2.0+3' in pubspec

legacy_bridge = (root / 'mechos_bridge/server.py').read_text()
assert "'/v1/optimization/report'" in legacy_bridge
assert 'def optimization_report()' in legacy_bridge
assert 'ACTIONS = {' in legacy_bridge and 'shutil.which' in legacy_bridge
assert 'nvidia-smi' in legacy_bridge and 'gpu_busy_percent' in legacy_bridge

bridge = (root / 'mechos_bridge/server_v020.py').read_text()
for endpoint in ['/v1/store/catalog', '/v1/store/install', '/v1/store/downloads']:
    assert endpoint in bridge
assert 'STORE_ITEMS' in bridge
assert 'RelayAgent' in bridge
assert 'MECHOS_RELAY_URL' in bridge

relay = (root / 'mechos_relay/server.py').read_text()
assert '/v1/agent/poll' in relay
assert '/v1/agent/respond' in relay
assert '/device/' in relay

image_service = (root / 'lib/services/report_image_service.dart').read_text()
assert '1080, 1920' in image_service
assert '1080, 1350' in image_service
assert 'ImageByteFormat.png' in image_service

share_service = (root / 'lib/services/report_share_service.dart').read_text()
assert 'Gal.putImage' in share_service
assert 'SharePlus.instance.share' in share_service
assert 'ShareParams(' in share_service

screen = (root / 'lib/screens/optimization_report_screen.dart').read_text()
for label in ['Scan Optimization', 'Generate Report Image', 'Save to Phone', 'Share to Discord']:
    assert label in screen

pairing = (root / 'lib/screens/pairing_screen.dart').read_text()
assert 'DeviceDiscoveryService' in pairing
assert 'Find your MechOS PC' in pairing

store_screen = (root / 'lib/screens/store_screen.dart').read_text()
assert 'Unified Store' in store_screen
assert 'Creator Store' in store_screen
assert 'Remote Downloads' in store_screen

api_doc = (root / 'docs/API.md').read_text()
assert 'arbitrary' in api_doc
assert '/v1/optimization/report' in api_doc
assert '/v1/store/install' in api_doc
assert 'MechOS Anywhere' in api_doc

print('MechOS Companion Mobile 0.2.0 source validation: PASS')
