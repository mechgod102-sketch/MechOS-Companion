import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/discovered_device.dart';

class DeviceDiscoveryService {
  static const serviceType = '_mechos-companion._tcp.local';

  Future<List<DiscoveredDevice>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final client = MDnsClient();
    final found = <String, DiscoveredDevice>{};

    try {
      await client.start();
      final ptrs = client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceType),
          )
          .timeout(timeout, onTimeout: (sink) => sink.close());

      await for (final ptr in ptrs) {
        final services = client
            .lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName),
            )
            .timeout(const Duration(seconds: 1), onTimeout: (sink) => sink.close());

        await for (final srv in services) {
          String? address;
          final ipv4 = client
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target),
              )
              .timeout(const Duration(milliseconds: 800), onTimeout: (sink) => sink.close());
          await for (final record in ipv4) {
            address = record.address.address;
            break;
          }

          address ??= srv.target.endsWith('.')
              ? srv.target.substring(0, srv.target.length - 1)
              : srv.target;
          final cleanName = ptr.domainName
              .replaceFirst('.$serviceType', '')
              .replaceAll(r'\032', ' ')
              .replaceAll(r'\.', '.');
          final device = DiscoveredDevice(
            name: cleanName.isEmpty ? 'MechOS PC' : cleanName,
            host: address,
            port: srv.port,
          );
          found[device.baseUrl] = device;
        }
      }
    } finally {
      client.stop();
    }

    final result = found.values.toList();
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}
