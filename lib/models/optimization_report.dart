class OptimizationFinding {
  const OptimizationFinding({
    required this.severity,
    required this.title,
    required this.detail,
  });

  final String severity;
  final String title;
  final String detail;

  factory OptimizationFinding.fromJson(Map<String, dynamic> json) => OptimizationFinding(
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? 'Finding',
        detail: json['detail'] as String? ?? '',
      );
}

class OptimizationReport {
  const OptimizationReport({
    required this.reportId,
    required this.generatedAt,
    required this.hostname,
    required this.osVersion,
    required this.buildChannel,
    required this.session,
    required this.radarAiState,
    required this.score,
    required this.cpuPercent,
    required this.gpuPercent,
    required this.ramPercent,
    required this.storagePercent,
    required this.cpuName,
    required this.gpuName,
    required this.ramUsedGb,
    required this.ramTotalGb,
    required this.storageUsedGb,
    required this.storageTotalGb,
    required this.temperatureC,
    required this.updateAvailable,
    required this.findings,
    required this.recommendedFixes,
  });

  final String reportId;
  final DateTime generatedAt;
  final String hostname;
  final String osVersion;
  final String buildChannel;
  final String session;
  final String radarAiState;
  final int score;
  final double cpuPercent;
  final double? gpuPercent;
  final double ramPercent;
  final double storagePercent;
  final String cpuName;
  final String gpuName;
  final double ramUsedGb;
  final double ramTotalGb;
  final double storageUsedGb;
  final double storageTotalGb;
  final double? temperatureC;
  final bool updateAvailable;
  final List<OptimizationFinding> findings;
  final List<String> recommendedFixes;

  factory OptimizationReport.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? const {};
    final hardware = json['hardware'] as Map<String, dynamic>? ?? const {};
    final findingsJson = json['findings'] as List<dynamic>? ?? const [];
    final fixesJson = json['recommended_fixes'] as List<dynamic>? ?? const [];
    final rawScore = (json['score'] as num? ?? 0).round();
    final safeScore = rawScore < 0 ? 0 : (rawScore > 100 ? 100 : rawScore);
    return OptimizationReport(
      reportId: json['report_id'] as String? ?? 'MCHS-UNKNOWN',
      generatedAt: DateTime.tryParse(json['generated_at'] as String? ?? '') ?? DateTime.now(),
      hostname: json['hostname'] as String? ?? 'MechOS',
      osVersion: json['os_version'] as String? ?? 'Unknown',
      buildChannel: json['build_channel'] as String? ?? 'Unknown',
      session: json['session'] as String? ?? 'Unknown',
      radarAiState: json['radarai_state'] as String? ?? 'Unknown',
      score: safeScore,
      cpuPercent: (metrics['cpu_percent'] as num? ?? 0).toDouble(),
      gpuPercent: (metrics['gpu_percent'] as num?)?.toDouble(),
      ramPercent: (metrics['ram_percent'] as num? ?? 0).toDouble(),
      storagePercent: (metrics['storage_percent'] as num? ?? 0).toDouble(),
      cpuName: hardware['cpu'] as String? ?? 'Unknown CPU',
      gpuName: hardware['gpu'] as String? ?? 'Unknown GPU',
      ramUsedGb: (hardware['ram_used_gb'] as num? ?? 0).toDouble(),
      ramTotalGb: (hardware['ram_total_gb'] as num? ?? 0).toDouble(),
      storageUsedGb: (hardware['storage_used_gb'] as num? ?? 0).toDouble(),
      storageTotalGb: (hardware['storage_total_gb'] as num? ?? 0).toDouble(),
      temperatureC: (metrics['temperature_c'] as num?)?.toDouble(),
      updateAvailable: json['update_available'] as bool? ?? false,
      findings: findingsJson
          .whereType<Map<String, dynamic>>()
          .map(OptimizationFinding.fromJson)
          .toList(),
      recommendedFixes: fixesJson.map((e) => e.toString()).toList(),
    );
  }

  static final demo = OptimizationReport(
    reportId: 'MCHS-DEMO-031-82A1',
    generatedAt: DateTime.now(),
    hostname: 'MechDeck',
    osVersion: 'MechOS 0.3.1-dev',
    buildChannel: 'Dev',
    session: 'MechScope',
    radarAiState: 'Healthy',
    score: 82,
    cpuPercent: 68,
    gpuPercent: 72,
    ramPercent: 63,
    storagePercent: 55,
    cpuName: 'AMD Custom APU',
    gpuName: 'AMD Radeon Graphics',
    ramUsedGb: 10.1,
    ramTotalGb: 16,
    storageUsedGb: 281.6,
    storageTotalGb: 512,
    temperatureC: 72,
    updateAvailable: true,
    findings: const [
      OptimizationFinding(severity: 'warning', title: 'High background CPU usage', detail: 'Background load is above the preferred gaming target.'),
      OptimizationFinding(severity: 'info', title: 'Shader cache cleanup recommended', detail: 'Old shader cache data can be reviewed and cleaned.'),
      OptimizationFinding(severity: 'warning', title: 'Update available', detail: 'A MechOS update is ready for review.'),
    ],
    recommendedFixes: const [
      'Close unnecessary background applications.',
      'Review and clear stale shader cache data.',
      'Review the available MechOS update.',
      'Keep at least 20% of storage free for updates and caches.',
    ],
  );
}
