class DiscoveredDevice {
  const DiscoveredDevice({
    required this.name,
    required this.host,
    required this.port,
  });

  final String name;
  final String host;
  final int port;

  String get baseUrl {
    final safeHost = host.contains(':') && !host.startsWith('[') ? '[$host]' : host;
    return 'http://$safeHost:$port';
  }
}
