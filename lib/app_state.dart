import 'package:flutter/foundation.dart';
import 'models/device_status.dart';
import 'models/download_task.dart';
import 'models/optimization_report.dart';
import 'models/radar_alert.dart';
import 'models/remote_frame.dart';
import 'models/store_item.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/secure_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store);

  final SecureStore store;
  SavedConnection? connection;
  DeviceStatus status = DeviceStatus.demo;
  OptimizationReport? optimizationReport;
  List<RadarAlert> alerts = const [];
  List<StoreItem> storeItems = const [];
  List<DownloadTask> downloads = const [];
  bool loading = false;
  bool demoMode = false;
  String connectionMode = 'Offline';
  String? activeBaseUrl;
  String? error;

  bool get isConnected => connection != null || demoMode;
  bool get remoteAvailable =>
      connection?.remoteEnabled == true &&
      (connection?.remoteUrl?.trim().isNotEmpty ?? false);

  Future<void> restore() async {
    connection = await store.load();
    if (connection != null) await refresh();
    notifyListeners();
  }

  Future<void> pair({
    required String baseUrl,
    required String code,
    required String mobileName,
  }) async {
    _busy(true);
    try {
      final client = MechApiClient(baseUrl: baseUrl);
      final result = await client.pair(code, mobileName);
      client.close();
      connection = SavedConnection(
        baseUrl: baseUrl,
        token: result.token,
        deviceName: result.deviceName,
        remoteUrl: result.remoteUrl,
        remoteEnabled: true,
      );
      await store.save(connection!);
      demoMode = false;
      optimizationReport = null;
      error = null;
      await refresh();
    } catch (e) {
      error = _cleanError(e);
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
      RadarAlert(
        severity: 'info',
        title: 'Demo alert',
        detail: 'RadarAI notifications will appear here.',
      ),
    ];
    storeItems = _demoStore;
    downloads = const [];
    connectionMode = 'Demo';
    activeBaseUrl = null;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (demoMode) {
      status = DeviceStatus.demo;
      storeItems = _demoStore;
      connectionMode = 'Demo';
      notifyListeners();
      return;
    }
    if (connection == null) return;
    _busy(true);
    try {
      status = await _withClient((client) => client.status());
      alerts = await _withClient((client) => client.alerts());
      await NotificationService.notifyRadarAlerts(alerts);
      await NotificationService.notifyUpdateState(
        available: status.updateAvailable,
        detail: status.updateAvailable
            ? '${connection?.deviceName ?? 'Your PC'} has a MechOS update ready to install.'
            : null,
      );
      error = null;
    } catch (e) {
      connectionMode = 'Offline';
      activeBaseUrl = null;
      error = _cleanError(e);
    } finally {
      _busy(false);
    }
  }

  Future<void> refreshStore() async {
    if (demoMode) {
      storeItems = _demoStore;
      notifyListeners();
      return;
    }
    try {
      storeItems = await _withClient((client) => client.storeCatalog());
      downloads = await _withClient((client) => client.downloads());
      error = null;
    } catch (e) {
      error = _cleanError(e);
    }
    notifyListeners();
  }

  Future<void> refreshDownloads() async {
    if (demoMode || connection == null) return;
    try {
      downloads = await _withClient((client) => client.downloads());
      error = null;
    } catch (e) {
      error = _cleanError(e);
    }
    notifyListeners();
  }

  Future<DownloadTask> installStoreItem(String itemId) async {
    if (demoMode) {
      final item = _demoStore.firstWhere((e) => e.id == itemId);
      final task = DownloadTask(
        id: 'demo-$itemId',
        itemId: itemId,
        name: item.name,
        state: 'installed',
        progress: 100,
        message: 'Demo mode install complete',
      );
      downloads = [task, ...downloads];
      notifyListeners();
      return task;
    }
    final task = await _withClient((client) => client.installStoreItem(itemId));
    await refreshDownloads();
    return task;
  }

  Future<RemoteFrame> fetchRemoteFrame({int quality = 55}) async {
    if (demoMode) throw Exception('Remote Control is unavailable in Demo Mode');
    if (connection == null) throw Exception('No paired MechOS device');
    return _withClient((client) => client.remoteFrame(quality: quality));
  }

  Future<void> sendRemoteInput(
    String type, {
    double? x,
    double? y,
    double? delta,
    String? key,
    String? text,
  }) async {
    if (demoMode) return;
    if (connection == null) throw Exception('No paired MechOS device');
    await _withClient(
      (client) => client.remoteInput(
        type,
        x: x,
        y: y,
        delta: delta,
        key: key,
        text: text,
      ),
    );
  }

  Future<OptimizationReport> scanOptimization() async {
    if (demoMode) {
      optimizationReport = OptimizationReport.demo;
      notifyListeners();
      return optimizationReport!;
    }
    if (connection == null) throw Exception('No paired MechOS device');
    _busy(true);
    try {
      optimizationReport = await _withClient((client) => client.optimizationReport());
      error = null;
      return optimizationReport!;
    } catch (e) {
      error = _cleanError(e);
      rethrow;
    } finally {
      _busy(false);
    }
  }

  Future<String> runAction(String action, {String? value}) async {
    if (demoMode) return 'Demo mode: $action';
    if (connection == null) throw Exception('No paired MechOS device');
    final result = await _withClient(
      (client) => client.action(action, value: value),
    );
    if (action == 'update_install') {
      await NotificationService.showUpdateStarted();
    }
    await refresh();
    return result;
  }

  Future<void> handleNotificationAction(String action) async {
    if (action == NotificationService.updateAction) {
      try {
        await runAction('update_install');
      } catch (e) {
        error = _cleanError(e);
        notifyListeners();
      }
    }
  }

  Future<void> setRemoteAccess({
    required bool enabled,
    String? remoteUrl,
  }) async {
    final current = connection;
    if (current == null) return;
    final normalized = remoteUrl?.trim();
    connection = current.copyWith(
      remoteEnabled: enabled,
      remoteUrl: normalized,
      clearRemoteUrl: normalized != null && normalized.isEmpty,
    );
    await store.save(connection!);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await store.clear();
    connection = null;
    optimizationReport = null;
    storeItems = const [];
    downloads = const [];
    demoMode = false;
    connectionMode = 'Offline';
    activeBaseUrl = null;
    error = null;
    notifyListeners();
  }

  Future<T> _withClient<T>(Future<T> Function(MechApiClient client) action) async {
    final current = connection;
    if (current == null) throw Exception('No paired MechOS device');

    final candidates = <({String url, String mode})>[
      (url: current.baseUrl, mode: 'Local Network'),
      if (current.remoteEnabled &&
          current.remoteUrl != null &&
          current.remoteUrl!.trim().isNotEmpty &&
          current.remoteUrl!.trim() != current.baseUrl)
        (url: current.remoteUrl!.trim(), mode: 'Remote / Cellular'),
    ];

    Object? lastError;
    for (final candidate in candidates) {
      final client = MechApiClient(baseUrl: candidate.url, token: current.token);
      try {
        final result = await action(client);
        connectionMode = candidate.mode;
        activeBaseUrl = candidate.url;
        return result;
      } catch (e) {
        lastError = e;
      } finally {
        client.close();
      }
    }
    connectionMode = 'Offline';
    activeBaseUrl = null;
    throw Exception(_cleanError(lastError ?? 'Connection failed'));
  }

  String _cleanError(Object value) =>
      value.toString().replaceFirst('Exception: ', '');

  void _busy(bool value) {
    loading = value;
    notifyListeners();
  }

  static const _demoStore = <StoreItem>[
    StoreItem(
      id: 'steam',
      name: 'Steam',
      description: 'Game library and launcher.',
      category: 'Games',
      creator: false,
      installable: true,
    ),
    StoreItem(
      id: 'discord',
      name: 'Discord',
      description: 'Voice, chat, and community app.',
      category: 'Communication',
      creator: false,
      installable: true,
    ),
    StoreItem(
      id: 'obs',
      name: 'OBS Studio',
      description: 'Streaming and recording suite.',
      category: 'Streaming',
      creator: true,
      installable: true,
    ),
    StoreItem(
      id: 'blender',
      name: 'Blender',
      description: '3D modeling, animation, and rendering.',
      category: '3D & Modeling',
      creator: true,
      installable: true,
    ),
    StoreItem(
      id: 'godot',
      name: 'Godot Engine',
      description: 'Open source game development engine.',
      category: 'Game Engines',
      creator: true,
      installable: true,
    ),
    StoreItem(
      id: 'krita',
      name: 'Krita',
      description: 'Digital painting and texture creation.',
      category: 'Art & Design',
      creator: true,
      installable: true,
    ),
  ];
}
