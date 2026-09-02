import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_status.dart';
import '../models/radar_alert.dart';
import '../models/optimization_report.dart';

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
    return items.map((e) => RadarAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OptimizationReport> optimizationReport() async {
    final response = await _http
        .get(Uri.parse('$baseUrl/v1/optimization/report'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    return OptimizationReport.fromJson(_decode(response));
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
