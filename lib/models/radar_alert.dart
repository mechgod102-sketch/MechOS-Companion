class RadarAlert {
  const RadarAlert({required this.severity, required this.title, required this.detail});
  final String severity;
  final String title;
  final String detail;

  factory RadarAlert.fromJson(Map<String, dynamic> json) => RadarAlert(
        severity: json['severity'] as String? ?? 'info',
        title: json['title'] as String? ?? 'RadarAI',
        detail: json['detail'] as String? ?? '',
      );
}
