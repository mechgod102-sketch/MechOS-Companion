import 'package:flutter/foundation.dart';
import 'models/device_status.dart';
import 'models/optimization_report.dart';
import 'models/radar_alert.dart';
import 'services/api_client.dart';
import 'services/secure_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store);
  final SecureStore store;
  SavedConnection? connection;
  DeviceStatus status = DeviceStatus.demo;
  OptimizationReport? optimizationReport;
  List<RadarAlert> alerts = const [];
  bool loading = false;
  bool demoMode = false;
  String? error;

  bool get isConnected => connection != null || demoMode;

  Future<void> restore() async {
    connection = await store.load();
    if (connection != null) await refresh();
    notifyListeners();
  }

  Future<void> pair({required String baseUrl, required String code, required String mobileName}) async {
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: baseUrl);
      final result = await client.pair(code, mobileName);
      client.close();
      connection = SavedConnection(baseUrl: baseUrl, token: result.token, deviceName: result.deviceName);
      await store.save(connection!);
      demoMode = false;
      optimizationReport = null;
      error = null;
      await refresh();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _busy(false);
    }
  }

  void useDemo() {
    demoMode = true;
    connection = null;
    status = DeviceStatus.demo;
    optimizationReport = OptimizationReport.demo;
    alerts = const [
      RadarAlert(severity: 'info', title: 'Demo alert', detail: 'RadarAI notifications will appear here.'),
    ];
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (demoMode) {
      status = DeviceStatus.demo;
      notifyListeners();
      return;
    }
    final c = connection;
    if (c == null) return;
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
      status = await client.status();
      alerts = await client.alerts();
      client.close();
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _busy(false);
    }
  }

  Future<OptimizationReport> scanOptimization() async {
    if (demoMode) {
      optimizationReport = OptimizationReport.demo;
      notifyListeners();
      return optimizationReport!;
    }
    final c = connection;
    if (c == null) throw Exception('No paired MechOS device');
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
      optimizationReport = await client.optimizationReport();
      client.close();
      error = null;
      return optimizationReport!;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _busy(false);
    }
  }

  Future<String> runAction(String action, {String? value}) async {
    if (demoMode) return 'Demo mode: $action';
    final c = connection;
    if (c == null) throw Exception('No paired MechOS device');
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      final result = await client.action(action, value: value);
      await refresh();
      return result;
    } finally {
      client.close();
    }
  }

  Future<void> disconnect() async {
    await store.clear();
    connection = null;
    optimizationReport = null;
    demoMode = false;
    error = null;
    notifyListeners();
  }

  void _busy(bool value) {
    loading = value;
    notifyListeners();
  }
}
