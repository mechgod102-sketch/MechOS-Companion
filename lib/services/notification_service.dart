import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radar_alert.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final action = response.actionId;
  if (action == null || action.isEmpty) return;
  final prefs = SharedPreferencesAsync();
  await prefs.setString(NotificationService.pendingActionKey, action);
}

class NotificationService {
  NotificationService._();

  static const pendingActionKey = 'mechos_pending_notification_action';
  static const _radarStateKey = 'mechos_last_radar_notification_state';
  static const _updateStateKey = 'mechos_last_update_notification_state';
  static const updateAction = 'update_now';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> Function(String action)? onAction;

  static Future<void> initialize({bool requestPermissions = true}) async {
    const android = AndroidInitializationSettings('ic_notification');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          'mechos_update',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              updateAction,
              'Update PC',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final action = response.actionId;
        if (action != null && action.isNotEmpty) {
          onAction?.call(action);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (requestPermissions) await requestNotificationPermissions();
  }

  static Future<void> requestNotificationPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> notifyRadarAlerts(List<RadarAlert> alerts) async {
    final prefs = SharedPreferencesAsync();
    final previous =
        (await prefs.getStringList(_radarStateKey) ?? const <String>[]).toSet();
    final current = alerts.map(_radarFingerprint).toSet();

    for (final alert in alerts) {
      final fingerprint = _radarFingerprint(alert);
      if (previous.contains(fingerprint)) continue;
      await _plugin.show(
        id: 4000 + (_stableHash(fingerprint) % 1000),
        title: 'RadarAI: ${alert.title}',
        body: alert.detail,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'mechos_radarai',
            'RadarAI alerts',
            channelDescription: 'Hardware and software alerts from RadarAI.',
            importance: alert.severity == 'critical'
                ? Importance.max
                : Importance.high,
            priority: alert.severity == 'critical'
                ? Priority.max
                : Priority.high,
            category: AndroidNotificationCategory.status,
          ),
          iOS: const DarwinNotificationDetails(
            threadIdentifier: 'mechos_radarai',
          ),
        ),
        payload: 'radarai',
      );
    }

    await prefs.setStringList(_radarStateKey, current.toList()..sort());
  }

  static Future<void> notifyUpdateState({
    required bool available,
    String? detail,
  }) async {
    final prefs = SharedPreferencesAsync();
    final wasAvailable = await prefs.getBool(_updateStateKey) ?? false;
    await prefs.setBool(_updateStateKey, available);
    if (!available || wasAvailable) return;

    await _plugin.show(
      id: 2100,
      title: 'MechOS system update available',
      body: detail ?? 'Your PC has a MechOS update ready to install.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mechos_updates',
          'MechOS updates',
          channelDescription: 'System update availability and install status.',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              updateAction,
              'Update PC',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'mechos_update',
          threadIdentifier: 'mechos_updates',
        ),
      ),
      payload: 'update_available',
    );
  }

  static Future<void> showUpdateStarted() async {
    await _plugin.show(
      id: 2101,
      title: 'MechOS update started',
      body: 'Your PC accepted the update request from Companion.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'mechos_updates',
          'MechOS updates',
          channelDescription: 'System update availability and install status.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'mechos_updates'),
      ),
      payload: 'update_started',
    );
  }

  static Future<String?> consumePendingAction() async {
    final prefs = SharedPreferencesAsync();
    final action = await prefs.getString(pendingActionKey);
    if (action != null) await prefs.remove(pendingActionKey);
    return action;
  }

  static String _radarFingerprint(RadarAlert alert) =>
      '${alert.severity}|${alert.title}|${alert.detail}';

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
