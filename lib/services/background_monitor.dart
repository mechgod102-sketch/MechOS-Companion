import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'secure_store.dart';

const _monitorTaskName = 'mechos_status_monitor';
const _monitorUniqueName = 'mechos-companion-status-monitor';

@pragma('vm:entry-point')
void companionBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await NotificationService.initialize(requestPermissions: false);
      final connection = await SecureStore().load();
      if (connection == null) return true;

      final candidates = <String>[
        connection.baseUrl,
        if (connection.remoteEnabled &&
            connection.remoteUrl != null &&
            connection.remoteUrl!.trim().isNotEmpty &&
            connection.remoteUrl!.trim() != connection.baseUrl)
          connection.remoteUrl!.trim(),
      ];

      for (final url in candidates) {
        final client = MechApiClient(baseUrl: url, token: connection.token);
        try {
          final status = await client.status();
          final alerts = await client.alerts();
          await NotificationService.notifyRadarAlerts(alerts);
          await NotificationService.notifyUpdateState(
            available: status.updateAvailable,
            detail: status.updateAvailable
                ? '${connection.deviceName} has a MechOS update ready to install.'
                : null,
          );
          return true;
        } catch (_) {
          // Try the next paired route (local first, relay second).
        } finally {
          client.close();
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  });
}

Future<void> initializeBackgroundMonitoring() async {
  await Workmanager().initialize(companionBackgroundDispatcher);
  await Workmanager().registerPeriodicTask(
    _monitorUniqueName,
    _monitorTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
