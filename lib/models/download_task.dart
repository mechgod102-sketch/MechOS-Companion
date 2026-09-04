class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.itemId,
    required this.name,
    required this.state,
    required this.progress,
    required this.message,
  });

  final String id;
  final String itemId;
  final String name;
  final String state;
  final int progress;
  final String message;

  bool get active => state == 'queued' || state == 'installing';
  bool get failed => state == 'failed';
  bool get completed => state == 'installed';

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'] as String? ?? '',
        itemId: json['item_id'] as String? ?? '',
        name: json['name'] as String? ?? 'Download',
        state: json['state'] as String? ?? 'queued',
        progress: (json['progress'] as num?)?.round().clamp(0, 100) ?? 0,
        message: json['message'] as String? ?? '',
      );
}
