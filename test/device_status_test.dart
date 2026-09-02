import 'package:flutter_test/flutter_test.dart';
import 'package:mechos_companion_mobile/models/device_status.dart';

void main() {
  test('status json parsing uses bridge fields', () {
    final s = DeviceStatus.fromJson({'hostname': 'Deck', 'ram_used_gb': 4, 'ram_total_gb': 16, 'update_available': true});
    expect(s.hostname, 'Deck');
    expect(s.ramUsedGb, 4);
    expect(s.updateAvailable, isTrue);
  });
}
