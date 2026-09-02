import 'optimization_report.dart';

class PerformanceSample {
  const PerformanceSample({
    required this.timestamp,
    required this.cpuPercent,
    required this.gpuPercent,
    required this.ramPercent,
    required this.storagePercent,
    required this.temperatureC,
  });

  final DateTime timestamp;
  final double cpuPercent;
  final double? gpuPercent;
  final double ramPercent;
  final double storagePercent;
  final double? temperatureC;

  factory PerformanceSample.fromJson(Map<String, dynamic> json) => PerformanceSample(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        cpuPercent: (json['cpu_percent'] as num? ?? 0).toDouble(),
        gpuPercent: (json['gpu_percent'] as num?)?.toDouble(),
        ramPercent: (json['ram_percent'] as num? ?? 0).toDouble(),
        storagePercent: (json['storage_percent'] as num? ?? 0).toDouble(),
        temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      );

  factory PerformanceSample.demo([int phase = 0]) => PerformanceSample(
        timestamp: DateTime.now(),
        cpuPercent: 42 + (phase % 6) * 4,
        gpuPercent: 55 + (phase % 5) * 6,
        ramPercent: 61 + (phase % 3),
        storagePercent: 55,
        temperatureC: 68 + (phase % 4) * 2,
      );
}

class GameCompatibility {
  const GameCompatibility({
    required this.name,
    required this.status,
    required this.detail,
    required this.source,
  });

  final String name;
  final String status;
  final String detail;
  final String source;

  factory GameCompatibility.fromJson(Map<String, dynamic> json) => GameCompatibility(
        name: json['name'] as String? ?? 'Unknown game',
        status: json['status'] as String? ?? 'Unknown',
        detail: json['detail'] as String? ?? '',
        source: json['source'] as String? ?? 'MechOS',
      );

  static const demo = [
    GameCompatibility(name: 'S.T.A.L.K.E.R. GAMMA', status: 'Profile available', detail: 'MechOS compatibility profile detected.', source: 'Demo catalog'),
    GameCompatibility(name: 'Path of Exile 2', status: 'Compatible profile', detail: 'Compatibility settings are ready to review.', source: 'Demo catalog'),
    GameCompatibility(name: 'Escape from Tarkov', status: 'Needs validation', detail: 'Anti-cheat and launcher status should be verified before play.', source: 'Demo catalog'),
  ];
}

class UpdateProgress {
  const UpdateProgress({
    required this.state,
    required this.progress,
    required this.phase,
    required this.message,
  });

  final String state;
  final double progress;
  final String phase;
  final String message;

  bool get active => state == 'downloading' || state == 'installing' || state == 'applying';

  factory UpdateProgress.fromJson(Map<String, dynamic> json) => UpdateProgress(
        state: json['state'] as String? ?? 'idle',
        progress: ((json['progress'] as num? ?? 0).toDouble()).clamp(0, 100).toDouble(),
        phase: json['phase'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  static const demo = UpdateProgress(state: 'downloading', progress: 64, phase: 'Downloading packages', message: 'MechOS 0.3.1 update in progress');
}

class CompanionNotification {
  const CompanionNotification({
    required this.id,
    required this.severity,
    required this.title,
    required this.detail,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String severity;
  final String title;
  final String detail;
  final String source;
  final DateTime createdAt;

  factory CompanionNotification.fromJson(Map<String, dynamic> json) => CompanionNotification(
        id: json['id'] as String? ?? '${json['source'] ?? 'alert'}-${json['title'] ?? 'notice'}',
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? 'MechOS notification',
        detail: json['detail'] as String? ?? '',
        source: json['source'] as String? ?? 'MechOS',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  factory CompanionNotification.demo() => CompanionNotification(
        id: 'demo-hardware',
        severity: 'warning',
        title: 'Hardware temperature elevated',
        detail: 'Demo alert: a temperature sensor crossed the warning threshold.',
        source: 'RadarAI',
        createdAt: DateTime.now(),
      );
}

class PairedMobileDevice {
  const PairedMobileDevice({required this.id, required this.name, required this.pairedAt, required this.current});

  final String id;
  final String name;
  final DateTime pairedAt;
  final bool current;

  factory PairedMobileDevice.fromJson(Map<String, dynamic> json) => PairedMobileDevice(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Mobile device',
        pairedAt: DateTime.fromMillisecondsSinceEpoch(((json['paired_at'] as num? ?? 0).toInt()) * 1000),
        current: json['current'] as bool? ?? false,
      );
}

class DeveloperBundle {
  const DeveloperBundle({required this.reportId, required this.optimizationReport, required this.raw});

  final String reportId;
  final OptimizationReport optimizationReport;
  final Map<String, dynamic> raw;

  factory DeveloperBundle.fromJson(Map<String, dynamic> json) {
    final reportJson = (json['optimization_report'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return DeveloperBundle(
      reportId: json['report_id'] as String? ?? reportJson['report_id'] as String? ?? 'MCHS-REPORT',
      optimizationReport: OptimizationReport.fromJson(reportJson),
      raw: json,
    );
  }
}
