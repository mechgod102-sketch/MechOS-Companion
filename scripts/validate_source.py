#!/usr/bin/env python3
from pathlib import Path
import ast

root = Path(__file__).resolve().parents[1]
required = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/app_state.dart',
    'lib/models/optimization_report.dart',
    'lib/services/api_client.dart',
    'lib/services/report_image_service.dart',
    'lib/services/report_share_service.dart',
    'lib/screens/optimization_report_screen.dart',
    'mechos_bridge/server.py',
    'scripts/bootstrap-platforms.sh',
    'scripts/apply_platform_patches.py',
]
missing = [p for p in required if not (root / p).exists()]
if missing:
    raise SystemExit('Missing: ' + ', '.join(missing))

ast.parse((root / 'mechos_bridge/server.py').read_text())
ast.parse((root / 'scripts/apply_platform_patches.py').read_text())

pubspec = (root / 'pubspec.yaml').read_text()
for dep in [
    'http: ^1.6.0',
    'flutter_secure_storage: ^11.0.0',
    'shared_preferences: ^2.5.5',
    'path_provider: ^2.1.5',
    'share_plus: ^10.1.4',
    'gal: ^2.3.2',
]:
    assert dep in pubspec, dep

bridge = (root / 'mechos_bridge/server.py').read_text()
assert "'/v1/optimization/report'" in bridge
assert 'def optimization_report()' in bridge
assert 'ACTIONS = {' in bridge and 'shutil.which' in bridge
assert 'nvidia-smi' in bridge and 'gpu_busy_percent' in bridge

image_service = (root / 'lib/services/report_image_service.dart').read_text()
assert '1080, 1920' in image_service
assert '1080, 1350' in image_service
assert 'ImageByteFormat.png' in image_service

share_service = (root / 'lib/services/report_share_service.dart').read_text()
assert 'Gal.putImage' in share_service
assert 'Share.shareXFiles' in share_service

screen = (root / 'lib/screens/optimization_report_screen.dart').read_text()
for label in ['Scan Optimization', 'Generate Report Image', 'Save to Phone', 'Share to Discord']:
    assert label in screen

api_doc = (root / 'docs/API.md').read_text()
assert 'arbitrary' in api_doc
assert '/v1/optimization/report' in api_doc

print('MechOS Companion Mobile 0.1.1 source validation: PASS')
