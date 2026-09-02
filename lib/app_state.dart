import 'package:flutter/foundation.dart';
import 'models/companion_features.dart';
import 'models/device_status.dart';
import 'models/optimization_report.dart';
import 'models/radar_alert.dart';
import 'services/api_client.dart';
import 'services/secure_store.dart';

enum ConnectionRoute { local, remote, offline, demo }

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
  ConnectionRoute connectionRoute = ConnectionRoute.offline;
  String? activeBaseUrl;

  bool get isConnected => connection != null || demoMode;
  bool get remoteConfigured => (connection?.remoteUrl?.trim().isNotEmpty ?? false);
  bool get isRemote => connectionRoute == ConnectionRoute.remote;

  String get connectionRouteLabel {
    switch (connectionRoute) {
      case ConnectionRoute.local:
        return 'Local';
      case ConnectionRoute.remote:
        return 'Remote';
      case ConnectionRoute.demo:
        return 'Demo';
      case ConnectionRoute.offline:
        return 'Offline';
    }
  }

  Future<void> restore() async {
    connection = await store.load();
    if (connection != null) await refresh();
    notifyListeners();
  }

  Future<void> pair({
    required String baseUrl,
    required String code,
    required String mobileName,
    String? remoteUrl,
  }) async {
    _busy(true);
    try {
      final local = _normalizeBaseUrl(baseUrl);
      final normalizedRemote = remoteUrl == null || remoteUrl.trim().isEmpty
          ? null
          : _normalizeRemoteUrl(remoteUrl);
      final client = MechApiClient(baseUrl: local);
      final result = await client.pair(code, mobileName);
      client.close();
      connection = SavedConnection(
        localUrl: local,
        remoteUrl: normalizedRemote,
        token: result.token,
        deviceName: result.deviceName,
      );
      await store.save(connection!);
      demoMode = false;
      activeBaseUrl = local;
      connectionRoute = ConnectionRoute.local;
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
    connectionRoute = ConnectionRoute.demo;
    activeBaseUrl = null;
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
      connectionRoute = ConnectionRoute.demo;
      notifyListeners();
      return;
    }
    if (connection == null) return;
    _busy(true);
    try {
      final endpoint = await _resolveEndpoint();
      final c = _requireConnection();
      final client = MechApiClient(baseUrl: endpoint, token: c.token);
      status = await client.status();
      alerts = await client.alerts();
      client.close();
      error = null;
    } catch (e) {
      connectionRoute = ConnectionRoute.offline;
      activeBaseUrl = null;
      error = _message(e);
    } finally {
      _busy(false);
    }
  }

  Future<String> testRemoteUrl(String remoteUrl) async {
    final normalized = _normalizeRemoteUrl(remoteUrl);
    final client = MechApiClient(baseUrl: normalized, token: connection?.token);
    try {
      final health = await client.health(timeout: 5);
      final version = health['version'] as String? ?? 'unknown version';
      return 'Remote bridge reachable • $version';
    } finally {
      client.close();
    }
  }

  Future<void> saveRemoteUrl(String remoteUrl) async {
    final c = _requireConnection();
    final trimmed = remoteUrl.trim();
    connection = trimmed.isEmpty
        ? c.copyWith(clearRemoteUrl: true)
        : c.copyWith(remoteUrl: _normalizeRemoteUrl(trimmed));
    await store.save(connection!);
    activeBaseUrl = null;
    connectionRoute = ConnectionRoute.offline;
    error = null;
    notifyListeners();
    await refresh();
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
      final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
      final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    final client = MechApiClient(baseUrl: await _resolveEndpoint(), token: c.token);
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
    connectionRoute = ConnectionRoute.offline;
    activeBaseUrl = null;
    error = null;
    notifyListeners();
  }

  Future<String> _resolveEndpoint() async {
    final c = _requireConnection();
    final candidates = <_EndpointCandidate>[];

    if (activeBaseUrl != null) {
      candidates.add(_EndpointCandidate(activeBaseUrl!, connectionRoute));
    }
    candidates.add(_EndpointCandidate(c.localUrl, ConnectionRoute.local));
    final remote = c.remoteUrl?.trim();
    if (remote != null && remote.isNotEmpty) {
      candidates.add(_EndpointCandidate(remote, ConnectionRoute.remote));
    }

    final seen = <String>{};
    for (final candidate in candidates) {
      if (!seen.add(candidate.url)) continue;
      final client = MechApiClient(baseUrl: candidate.url, token: c.token);
      try {
        await client.health(timeout: 3);
        activeBaseUrl = candidate.url;
        connectionRoute = candidate.route;
        return candidate.url;
      } catch (_) {
        // Try the next route. The bridge stays private; no public port probing is performed.
      } finally {
        client.close();
      }
    }

    connectionRoute = ConnectionRoute.offline;
    activeBaseUrl = null;
    throw Exception(remoteConfigured
        ? 'MechOS is unreachable on both local and remote private routes.'
        : 'MechOS is unreachable on the local network. Configure Remote Access for away-from-home use.');
  }

  SavedConnection _requireConnection() {
    final c = connection;
    if (c == null) throw Exception('No paired MechOS device');
    return c;
  }

  String _normalizeBaseUrl(String input) {
    final value = input.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception('Enter a valid MechOS Bridge address beginning with http:// or https://');
    }
    return value;
  }

  String _normalizeRemoteUrl(String input) {
    final value = _normalizeBaseUrl(input);
    final uri = Uri.parse(value);
    if (uri.scheme == 'https') return value;
    if (_isPrivateRemoteHost(uri.host)) return value;
    throw Exception('Remote HTTP is allowed only for private VPN/Tailscale addresses. Use HTTPS for any other hostname.');
  }

  bool _isPrivateRemoteHost(String host) {
    final lower = host.toLowerCase();
    if (lower.endsWith('.ts.net')) return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    if (a == 10 || a == 127) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    if (a == 100 && b >= 64 && b <= 127) return true; // Tailscale CGNAT range.
    return false;
  }

  String _message(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _busy(bool value) {
    loading = value;
    notifyListeners();
  }
}

class _EndpointCandidate {
  const _EndpointCandidate(this.url, this.route);
  final String url;
  final ConnectionRoute route;
}
