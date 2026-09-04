import 'dart:convert';
import 'dart:typed_data';

class RemoteFrame {
  const RemoteFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.capturedAt,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final DateTime capturedAt;

  factory RemoteFrame.fromJson(Map<String, dynamic> json) {
    final encoded = json['image_base64'] as String? ?? '';
    return RemoteFrame(
      bytes: base64Decode(encoded),
      width: (json['width'] as num?)?.round() ?? 0,
      height: (json['height'] as num?)?.round() ?? 0,
      capturedAt: DateTime.tryParse(json['captured_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
