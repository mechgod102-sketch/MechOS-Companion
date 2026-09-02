#!/usr/bin/env python3
"""Smoke-test the local optimization report builder without starting the HTTP server."""
from __future__ import annotations
import importlib.util
from pathlib import Path

root = Path(__file__).resolve().parents[1]
bridge_path = root / 'mechos_bridge' / 'server.py'
spec = importlib.util.spec_from_file_location('mechos_bridge_server', bridge_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

report = module.optimization_report()
required = {
    'report_id', 'generated_at', 'hostname', 'os_version', 'build_channel',
    'session', 'radarai_state', 'score', 'metrics', 'hardware', 'findings',
    'recommended_fixes',
}
missing = required - set(report)
if missing:
    raise SystemExit(f'Missing report fields: {sorted(missing)}')
if not 0 <= report['score'] <= 100:
    raise SystemExit(f"Invalid score: {report['score']}")
print('Bridge optimization report smoke test: PASS')
print(f"Report ID: {report['report_id']}")
print(f"Score: {report['score']}/100")
print(f"Metrics: {report['metrics']}")
