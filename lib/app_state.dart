import 'package:flutter/foundation.dart';
import 'models/companion_features.dart';
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
  PerformanceSample? latestPerformance;
  UpdateProgress? updateProgress;
  DeveloperBundle? developerBundle;
  List<RadarAlert> alerts = const [];
  List<GameCompatibility> games = const [];
  List<CompanionNotification> notifications = const [];
  List<PairedMobileDevice> pairedMobileDevices = const [];
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
      latestPerformance = null;
      developerBundle = null;
      error = null;
      await refresh();
    } catch (e) {
      error = _message(e);
    } finally {
      _busy(false);
    }
  }

  void useDemo() {
    demoMode = true;
    connection = null;
    status = DeviceStatus.demo;
    optimizationReport = OptimizationReport.demo;
    latestPerformance = PerformanceSample.demo();
    updateProgress = UpdateProgress.demo;
    games = GameCompatibility.demo;
    notifications = [CompanionNotification.demo()];
    pairedMobileDevices = [
      PairedMobileDevice(id: 'demo-phone', name: 'My phone', pairedAt: DateTime.now(), current: true),
    ];
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
      error = _message(e);
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
    final c = _requireConnection();
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
      optimizationReport = await client.optimizationReport();
      client.close();
      error = null;
      return optimizationReport!;
    } catch (e) {
      error = _message(e);
      rethrow;
    } finally {
      _busy(false);
    }
  }

  Future<PerformanceSample> fetchPerformance({int demoPhase = 0}) async {
    if (demoMode) {
      latestPerformance = PerformanceSample.demo(demoPhase);
      notifyListeners();
      return latestPerformance!;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      latestPerformance = await client.performanceSample();
      error = null;
      notifyListeners();
      return latestPerformance!;
    } catch (e) {
      error = _message(e);
      notifyListeners();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> loadCompatibility() async {
    if (demoMode) {
      games = GameCompatibility.demo;
      notifyListeners();
      return;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      games = await client.compatibilityCatalog();
      error = null;
    } catch (e) {
      error = _message(e);
    } finally {
      client.close();
      notifyListeners();
    }
  }

  Future<void> loadUpdateProgress() async {
    if (demoMode) {
      updateProgress = UpdateProgress.demo;
      notifyListeners();
      return;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      updateProgress = await client.updateProgress();
      error = null;
    } catch (e) {
      error = _message(e);
    } finally {
      client.close();
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    if (demoMode) {
      notifications = [CompanionNotification.demo()];
      notifyListeners();
      return;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      notifications = await client.notifications();
      error = null;
    } catch (e) {
      error = _message(e);
    } finally {
      client.close();
      notifyListeners();
    }
  }

  Future<void> loadPairedDevices() async {
    if (demoMode) {
      pairedMobileDevices = [
        PairedMobileDevice(id: 'demo-phone', name: 'My phone', pairedAt: DateTime.now(), current: true),
        PairedMobileDevice(id: 'demo-tablet', name: 'Dev tablet', pairedAt: DateTime.now().subtract(const Duration(days: 3)), current: false),
      ];
      notifyListeners();
      return;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      pairedMobileDevices = await client.pairedDevices();
      error = null;
    } catch (e) {
      error = _message(e);
    } finally {
      client.close();
      notifyListeners();
    }
  }

  Future<void> revokePairedDevice(String id) async {
    if (demoMode) {
      pairedMobileDevices = pairedMobileDevices.where((d) => d.id != id).toList();
      notifyListeners();
      return;
    }
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      await client.revokeDevice(id);
      pairedMobileDevices = await client.pairedDevices();
      error = null;
    } catch (e) {
      error = _message(e);
      rethrow;
    } finally {
      client.close();
      notifyListeners();
    }
  }

  Future<DeveloperBundle> generateDeveloperBundle() async {
    if (demoMode) {
      final report = OptimizationReport.demo;
      developerBundle = DeveloperBundle(
        reportId: report.reportId,
        optimizationReport: report,
        raw: {
          'report_id': report.reportId,
          'generated_at': DateTime.now().toIso8601String(),
          'summary': 'Demo MechOS developer bundle',
          'logs': {'radarai': 'Demo RadarAI log', 'bridge': 'Demo bridge log'},
        },
      );
      notifyListeners();
      return developerBundle!;
    }
    final c = _requireConnection();
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
      developerBundle = await client.developerBundle();
      client.close();
      optimizationReport = developerBundle!.optimizationReport;
      error = null;
      return developerBundle!;
    } catch (e) {
      error = _message(e);
      rethrow;
    } finally {
      _busy(false);
    }
  }

  Future<String> runAction(String action, {String? value}) async {
    if (demoMode) return 'Demo mode: $action';
    final c = _requireConnection();
    final client = MechApiClient(baseUrl: c.baseUrl, token: c.token);
    try {
      final result = await client.action(action, value: value);
      await refresh();
      if (action.startsWith('update')) await loadUpdateProgress();
      return result;
    } finally {
      client.close();
    }
  }

  Future<void> disconnect() async {
    await store.clear();
    connection = null;
    optimizationReport = null;
    latestPerformance = null;
    updateProgress = null;
    developerBundle = null;
    games = const [];
    notifications = const [];
    pairedMobileDevices = const [];
    demoMode = false;
    error = null;
    notifyListeners();
  }

  SavedConnection _requireConnection() {
    final c = connection;
    if (c == null) throw Exception('No paired MechOS device');
    return c;
  }

  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _busy(bool value) {
    loading = value;
    notifyListeners();
  }
}
