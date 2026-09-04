import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key, required this.state});
  final AppState state;

  Future<void> _scan(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(SnackBar(content: Text(await state.runAction('radarai_scan'))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _enableNotifications(BuildContext context) async {
    await NotificationService.requestNotificationPermissions();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RadarAI and MechOS update notifications enabled where permitted by the phone.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('RadarAI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('System health, issue reporting, and phone alerts from your paired MechOS device.', style: TextStyle(color: MechTheme.subtle)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: MechTheme.glow),
                        SizedBox(width: 10),
                        Expanded(child: Text('Phone notifications', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'New RadarAI alerts and MechOS system updates can notify this phone. Repeated identical alerts are suppressed until the condition clears and returns.',
                      style: TextStyle(color: MechTheme.subtle, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _enableNotifications(context),
                      icon: const Icon(Icons.notifications_rounded),
                      label: const Text('Enable / confirm notifications'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _scan(context),
              icon: const Icon(Icons.radar),
              label: const Text('Run quick scan'),
            ),
            const SizedBox(height: 16),
            if (state.alerts.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No active RadarAI alerts.'))))
            else
              ...state.alerts.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        a.severity == 'critical'
                            ? Icons.error
                            : a.severity == 'warning'
                                ? Icons.warning_amber
                                : Icons.info_outline,
                        color: a.severity == 'critical'
                            ? MechTheme.danger
                            : a.severity == 'warning'
                                ? MechTheme.warning
                                : MechTheme.primary,
                      ),
                      title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(a.detail),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
