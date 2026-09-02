class DeviceStatus {
  const DeviceStatus({
    required this.hostname,
    required this.osVersion,
    required this.kernel,
    required this.cpu,
    required this.gpu,
    required this.ramUsedGb,
    required this.ramTotalGb,
    required this.storageUsedGb,
    required this.storageTotalGb,
    required this.session,
    required this.updateAvailable,
    required this.radarAiState,
  });

  final String hostname;
  final String osVersion;
  final String kernel;
  final String cpu;
  final String gpu;
  final double ramUsedGb;
  final double ramTotalGb;
  final double storageUsedGb;
  final double storageTotalGb;
  final String session;
  final bool updateAvailable;
  final String radarAiState;

  factory DeviceStatus.fromJson(Map<String, dynamic> json) => DeviceStatus(
        hostname: json['hostname'] as String? ?? 'MechOS',
        osVersion: json['os_version'] as String? ?? 'Unknown',
        kernel: json['kernel'] as String? ?? 'Unknown',
        cpu: json['cpu'] as String? ?? 'Unknown',
        gpu: json['gpu'] as String? ?? 'Unknown',
        ramUsedGb: (json['ram_used_gb'] as num? ?? 0).toDouble(),
        ramTotalGb: (json['ram_total_gb'] as num? ?? 0).toDouble(),
        storageUsedGb: (json['storage_used_gb'] as num? ?? 0).toDouble(),
        storageTotalGb: (json['storage_total_gb'] as num? ?? 0).toDouble(),
        session: json['session'] as String? ?? 'Unknown',
        updateAvailable: json['update_available'] as bool? ?? false,
        radarAiState: json['radarai_state'] as String? ?? 'Unknown',
      );

  static const demo = DeviceStatus(
    hostname: 'MechDeck',
    osVersion: 'MechOS 0.3.1-dev',
    kernel: 'Linux (demo)',
    cpu: 'AMD Custom APU',
    gpu: 'AMD Radeon Graphics',
    ramUsedGb: 8.2,
    ramTotalGb: 16,
    storageUsedGb: 310,
    storageTotalGb: 512,
    session: 'MechScope',
    updateAvailable: true,
    radarAiState: 'Healthy',
  );
}
