import 'package:flutter_test/flutter_test.dart';
import 'package:mechos_companion_mobile/models/companion_features.dart';

void main() {
  test('performance sample parses live telemetry', () {
    final sample = PerformanceSample.fromJson({
      'timestamp': '2026-09-02T07:00:00Z',
      'cpu_percent': 52.5,
      'gpu_percent': 71,
      'ram_percent': 63,
      'storage_percent': 55,
      'temperature_c': 72,
    });
    expect(sample.cpuPercent, 52.5);
    expect(sample.gpuPercent, 71);
    expect(sample.temperatureC, 72);
  });

  test('update progress is clamped to percent range', () {
    final progress = UpdateProgress.fromJson({'state': 'downloading', 'progress': 140, 'phase': 'Packages'});
    expect(progress.progress, 100);
    expect(progress.active, isTrue);
  });

  test('game compatibility fields are normalized', () {
    final game = GameCompatibility.fromJson({'name': 'Test Game', 'status': 'Compatible', 'detail': 'Ready', 'source': 'catalog'});
    expect(game.name, 'Test Game');
    expect(game.status, 'Compatible');
  });
}
