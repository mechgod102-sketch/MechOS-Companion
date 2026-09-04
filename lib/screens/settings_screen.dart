import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = state.connection;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Connection, security, notifications, and MechOS Anywhere.', style: TextStyle(color: MechTheme.subtle)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.computer_rounded, color: MechTheme.glow),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.demoMode ? 'Demo Mode' : (c?.deviceName ?? 'Not paired'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                    _statusChip(state.connectionMode),
                  ],
                ),
                const SizedBox(height: 12),
                _row('Local address', state.demoMode ? 'Demo' : (c?.baseUrl ?? 'Not configured')),
                _row('Active route', state.connectionMode),
                if (!state.demoMode) _row('Remote route', c?.remoteUrl ?? 'Not configured'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!state.demoMode && c != null)
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.public_rounded, color: MechTheme.glow),
                  title: const Text('MechOS Anywhere', style: TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: const Text('Allow automatic fallback to the secure remote route when the PC is not reachable on local Wi-Fi.'),
                  value: c.remoteEnabled,
                  onChanged: (value) => state.setRemoteAccess(enabled: value),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Remote relay address'),
                  subtitle: Text(c.remoteUrl?.isNotEmpty == true ? c.remoteUrl! : 'Set by the bridge automatically, or enter one manually.'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _editRemoteUrl(context),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded, color: MechTheme.glow),
                title: const Text('RadarAI + update notifications'),
                subtitle: const Text('Background checks notify this phone about new RadarAI alerts and MechOS system updates.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await NotificationService.requestNotificationPermissions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification permission checked.')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.cast_connected_rounded, color: MechTheme.glow),
                title: Text('Remote Control'),
                subtitle: Text('PC screen frames and touch/keyboard input require the paired-device token.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.security_rounded, color: MechTheme.success),
                title: Text('Paired-device authentication'),
                subtitle: Text('The device token is kept in Android Keystore / Apple Keychain through secure storage.'),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.download_for_offline_outlined),
                title: Text('Remote Store installs'),
                subtitle: Text('Only catalog items approved by the MechOS bridge can be installed remotely.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('MechOS Companion Mobile'),
            subtitle: Text('Version 0.2.1 • Remote Control + RadarAI notifications'),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: state.disconnect,
          icon: const Icon(Icons.link_off_rounded),
          label: const Text('Disconnect device'),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Future<void> _editRemoteUrl(BuildContext context) async {
    final controller = TextEditingController(text: state.connection?.remoteUrl ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MechOS Anywhere relay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the HTTPS device URL exposed by your MechOS relay.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://relay.example/device/my-pc',
                prefixIcon: Icon(Icons.public_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await state.setRemoteAccess(enabled: true, remoteUrl: value);
    }
  }

  Widget _row(String key, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 105, child: Text(key, style: const TextStyle(color: MechTheme.subtle, fontSize: 12))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );

  Widget _statusChip(String value) {
    final remote = value == 'Remote / Cellular';
    final online = value != 'Offline';
    final color = !online ? MechTheme.danger : remote ? MechTheme.glow : MechTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(value, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
