import 'package:flutter_test/flutter_test.dart';
import 'package:mechos_companion_mobile/models/optimization_report.dart';

void main() {
  test('optimization report parses bridge response', () {
    final report = OptimizationReport.fromJson({
      'report_id': 'MCHS-TEST',
      'generated_at': '2026-09-02T01:00:00Z',
      'hostname': 'MechDeck',
      'os_version': 'MechOS 0.3.1-dev',
      'build_channel': 'Dev',
      'session': 'MechScope',
      'radarai_state': 'Healthy',
      'score': 82,
      'update_available': true,
      'metrics': {
        'cpu_percent': 68,
        'gpu_percent': 72,
        'ram_percent': 63,
        'storage_percent': 55,
        'temperature_c': 72,
      },
      'hardware': {
        'cpu': 'CPU',
        'gpu': 'GPU',
        'ram_used_gb': 10,
        'ram_total_gb': 16,
        'storage_used_gb': 281,
        'storage_total_gb': 512,
      },
      'findings': [
        {'severity': 'warning', 'title': 'Test', 'detail': 'Test detail'}
      ],
      'recommended_fixes': ['Test fix'],
    });

    expect(report.reportId, 'MCHS-TEST');
    expect(report.score, 82);
    expect(report.gpuPercent, 72);
    expect(report.findings.single.title, 'Test');
    expect(report.recommendedFixes.single, 'Test fix');
  });
}
