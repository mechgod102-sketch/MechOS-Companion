import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import 'controls_screen.dart';
import 'developer_report_screen.dart';
import 'devices_screen.dart';
import 'notifications_screen.dart';
import 'radar_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.state});
  final AppState state;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('More', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('RadarAI, remote controls, developer reporting, devices, and settings.', style: TextStyle(color: MechTheme.subtle)),
          const SizedBox(height: 16),
          _ToolTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications & Hardware Alerts',
            subtitle: 'Live RadarAI and hardware fault notification center',
            onTap: () => _open(context, NotificationsScreen(state: state)),
          ),
          _ToolTile(
            icon: Icons.radar,
            title: 'RadarAI',
            subtitle: 'Health, alerts, and quick scan controls',
            onTap: () => _open(context, RadarScreen(state: state)),
          ),
          _ToolTile(
            icon: Icons.tune,
            title: 'MechOS Controls',
            subtitle: 'MechScope/Desktop, updates, restart, and shutdown',
            onTap: () => _open(context, ControlsScreen(state: state)),
          ),
          _ToolTile(
            icon: Icons.bug_report_outlined,
            title: 'Developer Bug Report',
            subtitle: 'Optimization image + logs for Discord and GitHub',
            onTap: () => _open(context, DeveloperReportScreen(state: state)),
          ),
          _ToolTile(
            icon: Icons.devices,
            title: 'Paired Mobile Devices',
            subtitle: 'Review companion devices paired with this MechOS system',
            onTap: () => _open(context, DevicesScreen(state: state)),
          ),
          _ToolTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Connection details, security, and app version',
            onTap: () => _open(context, SettingsScreen(state: state)),
          ),
        ],
      );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(icon, color: MechTheme.primary),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(subtitle, style: const TextStyle(color: MechTheme.subtle)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      );
}
