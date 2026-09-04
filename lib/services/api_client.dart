import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_status.dart';
import '../models/download_task.dart';
import '../models/optimization_report.dart';
import '../models/radar_alert.dart';
import '../models/remote_frame.dart';
import '../models/store_item.dart';

class PairResult {
  const PairResult({
    required this.token,
    required this.deviceName,
    this.remoteUrl,
  });

  final String token;
  final String deviceName;
  final String? remoteUrl;
}

class MechApiClient {
  MechApiClient({required String baseUrl, this.token})
      : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final String baseUrl;
  final String? token;
  final http.Client _http = http.Client();

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<PairResult> pair(String code, String mobileName) async {
    final response = await _http
        .post(
          Uri.parse('$baseUrl/v1/pair'),
          headers: _headers,
          body: jsonEncode({'code': code, 'device_name': mobileName}),
        )
        .timeout(const Duration(seconds: 8));
    final body = _decode(response);
    return PairResult(
      token: body['token'] as String,
      deviceName: body['mechos_name'] as String? ?? 'MechOS',
      remoteUrl: body['remote_url'] as String?,
    );
  }

  Future<DeviceStatus> status() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/status'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return DeviceStatus.fromJson(_decode(response));
  }

  Future<List<RadarAlert>> alerts() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/radarai/alerts'), headers: _headers)
        .timeout(const Duration(seconds: 8));
    final body = _decode(response);
    final items = body['alerts'] as List<dynamic>? ?? const [];
    return items
        .map((e) => RadarAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OptimizationReport> optimizationReport() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/optimization/report'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    return OptimizationReport.fromJson(_decode(response));
  }

  Future<List<StoreItem>> storeCatalog() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/store/catalog'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    final items = body['items'] as List<dynamic>? ?? const [];
    return items
        .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DownloadTask>> downloads() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/store/downloads'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    final body = _decode(response);
    final items = body['downloads'] as List<dynamic>? ?? const [];
    return items
        .map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DownloadTask> installStoreItem(String itemId) async {
    final response = await _http
        .post(
          Uri.parse('$baseUrl/v1/store/install'),
          headers: _headers,
          body: jsonEncode({'item_id': itemId}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decode(response);
    return DownloadTask.fromJson(body['download'] as Map<String, dynamic>);
  }

  Future<RemoteFrame> remoteFrame({int quality = 55}) async {
    final q = quality.clamp(30, 80);
    final response = await _http
        .get(
          Uri.parse('$baseUrl/v1/remote/frame?quality=$q'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 12));
    return RemoteFrame.fromJson(_decode(response));
  }

  Future<void> remoteInput(
    String type, {
    double? x,
    double? y,
    double? delta,
    String? key,
    String? text,
  }) async {
    final payload = <String, dynamic>{'type': type};
    if (x != null) payload['x'] = x.clamp(0, 1);
    if (y != null) payload['y'] = y.clamp(0, 1);
    if (delta != null) payload['delta'] = delta.clamp(-10, 10);
    if (key != null) payload['key'] = key;
    if (text != null) payload['text'] = text;

    final response = await _http
        .post(
          Uri.parse('$baseUrl/v1/remote/input'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 8));
    _decode(response);
  }

  Future<String> action(String action, {String? value}) async {
    final payload = <String, dynamic>{'action': action};
    if (value != null) payload['value'] = value;

    final response = await _http
        .post(
          Uri.parse('$baseUrl/v1/action'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    return body['message'] as String? ?? 'Action sent';
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['error'] ?? 'Bridge returned HTTP ${response.statusCode}');
    }
    return body;
  }

  void close() => _http.close();
}
