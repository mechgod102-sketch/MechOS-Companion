import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/action_card.dart';
import 'remote_control_screen.dart';

class ControlsScreen extends StatelessWidget {
  const ControlsScreen({super.key, required this.state});
  final AppState state;

  Future<void> _confirm(
    BuildContext context,
    String title,
    String detail,
    String action, {
    String? value,
  }) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(SnackBar(content: Text(await state.runAction(action, value: value))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _openRemote(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Remote Control')),
          body: SafeArea(child: RemoteControlScreen(state: state)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Controls', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Remote actions are executed by allow-listed MechOS helper commands.', style: TextStyle(color: Color(0xFF9CA7C6))),
          const SizedBox(height: 16),
          ActionCard(
            icon: Icons.cast_connected_rounded,
            title: 'Remote Control',
            subtitle: 'Stream the PC screen to your phone and use touch controls',
            onTap: () => _openRemote(context),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.radar_rounded,
            title: 'Run RadarAI scan',
            subtitle: 'Scan the PC and refresh phone alerts',
            onTap: () => _confirm(context, 'Run RadarAI scan?', 'RadarAI will perform a quick health scan on the paired PC.', 'radarai_scan'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.sports_esports,
            title: 'Switch to MechScope',
            subtitle: 'Enter the gaming session',
            onTap: () => _confirm(context, 'Switch session?', 'This will request MechScope on the paired device.', 'session', value: 'mechscope'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.desktop_windows,
            title: 'Switch to Desktop',
            subtitle: 'Enter the desktop session',
            onTap: () => _confirm(context, 'Switch session?', 'This will request Desktop mode on the paired device.', 'session', value: 'desktop'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.system_update,
            title: 'Check for updates',
            subtitle: 'Ask MechOS Updater for the latest update state',
            onTap: () => _confirm(context, 'Check for updates?', 'This checks update availability without installing anything.', 'update_check'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.download_for_offline,
            title: 'Update PC now',
            subtitle: state.status.updateAvailable ? 'A MechOS update is available' : 'Run the normal MechOS update helper',
            onTap: () => _confirm(context, 'Install MechOS update?', 'The paired PC will start its normal MechOS system update process.', 'update_install'),
          ),
          const SizedBox(height: 24),
          const Text('Quick power options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.lock_outline_rounded,
            title: 'Lock PC',
            subtitle: 'Lock the current MechOS session',
            onTap: () => _confirm(context, 'Lock PC?', 'This will lock the paired MechOS session.', 'lock'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.bedtime_outlined,
            title: 'Sleep PC',
            subtitle: 'Put the paired PC into sleep mode',
            onTap: () => _confirm(context, 'Sleep PC?', 'The remote connection will disconnect until the PC wakes again.', 'sleep'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.restart_alt,
            title: 'Restart MechOS',
            subtitle: 'Restart the paired computer',
            danger: true,
            onTap: () => _confirm(context, 'Restart MechOS?', 'Unsaved work on the paired device can be lost.', 'restart'),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.power_settings_new,
            title: 'Shut down MechOS',
            subtitle: 'Power off the paired computer',
            danger: true,
            onTap: () => _confirm(context, 'Shut down MechOS?', 'Unsaved work on the paired device can be lost.', 'shutdown'),
          ),
        ],
      );
}
