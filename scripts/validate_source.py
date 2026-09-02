#!/usr/bin/env python3
from pathlib import Path
import ast

root = Path(__file__).resolve().parents[1]
required = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/app_state.dart',
    'lib/models/optimization_report.dart',
    'lib/models/companion_features.dart',
    'lib/services/api_client.dart',
    'lib/services/report_image_service.dart',
    'lib/services/report_share_service.dart',
    'lib/services/developer_bundle_service.dart',
    'lib/screens/optimization_report_screen.dart',
    'lib/screens/performance_screen.dart',
    'lib/screens/games_screen.dart',
    'lib/screens/notifications_screen.dart',
    'lib/screens/devices_screen.dart',
    'lib/screens/developer_report_screen.dart',
    'lib/screens/more_screen.dart',
    'mechos_bridge/server.py',
    'mechos_bridge/server_v012.py',
    'scripts/bootstrap-platforms.sh',
    'scripts/apply_platform_patches.py',
    'test/optimization_report_test.dart',
    'test/companion_features_test.dart',
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit('Missing: ' + ', '.join(missing))

ast.parse((root / 'mechos_bridge/server.py').read_text())
ast.parse((root / 'mechos_bridge/server_v012.py').read_text())
ast.parse((root / 'scripts/apply_platform_patches.py').read_text())

pubspec = (root / 'pubspec.yaml').read_text()
assert 'version: 0.1.2+3' in pubspec
for dep in [
    'http: ^1.6.0',
    'flutter_secure_storage: ^10.2.0',
    'shared_preferences: ^2.5.5',
    'path_provider: ^2.1.5',
    'share_plus: ^13.3.0',
    'gal: ^2.3.2',
]:
    assert dep in pubspec, dep

base_bridge = (root / 'mechos_bridge/server.py').read_text()
assert "'/v1/optimization/report'" in base_bridge
assert 'def optimization_report()' in base_bridge
assert 'ACTIONS = {' in base_bridge and 'shutil.which' in base_bridge
assert 'nvidia-smi' in base_bridge and 'gpu_busy_percent' in base_bridge

feature_bridge = (root / 'mechos_bridge/server_v012.py').read_text()
for endpoint in [
    '/v1/performance/live',
    '/v1/games/compatibility',
    '/v1/update/progress',
    '/v1/notifications',
    '/v1/devices',
    '/v1/developer/bug-report',
]:
    assert endpoint in feature_bridge, endpoint
assert 'compatibility_catalog' in feature_bridge
assert 'developer_bug_report' in feature_bridge
assert 'ThreadingHTTPServer' in feature_bridge

image_service = (root / 'lib/services/report_image_service.dart').read_text()
assert '1080, 1920' in image_service
assert '1080, 1350' in image_service
assert 'ImageByteFormat.png' in image_service

share_service = (root / 'lib/services/report_share_service.dart').read_text()
assert 'Gal.putImage' in share_service
assert 'SharePlus.instance.share' in share_service
assert 'ShareParams(' in share_service

developer_service = (root / 'lib/services/developer_bundle_service.dart').read_text()
assert 'GitHub-ready' in developer_service
assert 'application/json' in developer_service
assert 'text/markdown' in developer_service

optimize_screen = (root / 'lib/screens/optimization_report_screen.dart').read_text()
for label in ['Scan Optimization', 'Generate Report Image', 'Save to Phone', 'Share to Discord']:
    assert label in optimize_screen

home = (root / 'lib/screens/home_shell.dart').read_text()
for label in ["label: 'Home'", "label: 'Live'", "label: 'Optimize'", "label: 'Games'", "label: 'More'"]:
    assert label in home

api_doc = (root / 'docs/API.md').read_text()
assert 'arbitrary' in api_doc
assert '/v1/optimization/report' in api_doc
assert '/v1/developer/bug-report' in api_doc

print('MechOS Companion Mobile 0.1.2 source validation: PASS')
