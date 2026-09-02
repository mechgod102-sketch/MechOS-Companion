import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/companion_features.dart';
import '../models/device_status.dart';
import '../models/optimization_report.dart';
import '../models/radar_alert.dart';

class PairResult {
  const PairResult({required this.token, required this.deviceName});
  final String token;
  final String deviceName;
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
    final body = await _post('/v1/pair', {'code': code, 'device_name': mobileName}, timeout: 8);
    return PairResult(
      token: body['token'] as String,
      deviceName: body['mechos_name'] as String? ?? 'MechOS',
    );
  }

  Future<DeviceStatus> status() async => DeviceStatus.fromJson(await _get('/v1/status'));

  Future<List<RadarAlert>> alerts() async {
    final body = await _get('/v1/radarai/alerts');
    final items = body['alerts'] as List<dynamic>? ?? const [];
    return items.map((e) => RadarAlert.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<OptimizationReport> optimizationReport() async =>
      OptimizationReport.fromJson(await _get('/v1/optimization/report', timeout: 15));

  Future<PerformanceSample> performanceSample() async =>
      PerformanceSample.fromJson(await _get('/v1/performance/live'));

  Future<List<GameCompatibility>> compatibilityCatalog() async {
    final body = await _get('/v1/games/compatibility');
    final items = body['games'] as List<dynamic>? ?? const [];
    return items.map((e) => GameCompatibility.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<UpdateProgress> updateProgress() async =>
      UpdateProgress.fromJson(await _get('/v1/update/progress'));

  Future<List<CompanionNotification>> notifications() async {
    final body = await _get('/v1/notifications');
    final items = body['notifications'] as List<dynamic>? ?? const [];
    return items.map((e) => CompanionNotification.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<List<PairedMobileDevice>> pairedDevices() async {
    final body = await _get('/v1/devices');
    final items = body['devices'] as List<dynamic>? ?? const [];
    return items.map((e) => PairedMobileDevice.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> revokeDevice(String id) async {
    await _post('/v1/device/revoke', {'id': id});
  }

  Future<DeveloperBundle> developerBundle() async =>
      DeveloperBundle.fromJson(await _get('/v1/developer/bug-report', timeout: 25));

  Future<String> action(String action, {String? value}) async {
    final payload = <String, dynamic>{'action': action};
    if (value != null) payload['value'] = value;
    final body = await _post('/v1/action', payload, timeout: 95);
    return body['message'] as String? ?? 'Action sent';
  }

  Future<Map<String, dynamic>> _get(String path, {int timeout = 8}) async {
    final response = await _http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(Duration(seconds: timeout));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> payload, {int timeout = 20}) async {
    final response = await _http
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(payload))
        .timeout(Duration(seconds: timeout));
    return _decode(response);
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
