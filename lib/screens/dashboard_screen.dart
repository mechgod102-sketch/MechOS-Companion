import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/stat_card.dart';
import 'remote_control_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  Future<void> _run(BuildContext context, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(SnackBar(content: Text(await state.runAction(action))));
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
  Widget build(BuildContext context) {
    final s = state.status;
    final ramPct = s.ramTotalGb <= 0 ? 0.0 : s.ramUsedGb / s.ramTotalGb;
    final diskPct = s.storageTotalGb <= 0 ? 0.0 : s.storageUsedGb / s.storageTotalGb;
    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.hostname, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              Text('${s.osVersion} • ${state.connectionMode}', style: const TextStyle(color: MechTheme.subtle)),
            ])),
            IconButton(onPressed: state.loading ? null : state.refresh, icon: const Icon(Icons.refresh)),
          ]),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.wifi_off, color: MechTheme.danger), const SizedBox(width: 10), Expanded(child: Text(state.error!))]))),
          ],
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              StatCard(label: 'Session', value: s.session, icon: Icons.sports_esports, detail: 'MechScope / Desktop'),
              StatCard(label: 'RadarAI', value: s.radarAiState, icon: Icons.radar, detail: '${state.alerts.length} active alerts'),
              StatCard(label: 'Memory', value: '${s.ramUsedGb.toStringAsFixed(1)} GB', icon: Icons.memory, detail: '${(ramPct * 100).clamp(0, 100).toStringAsFixed(0)}% of ${s.ramTotalGb.toStringAsFixed(0)} GB'),
              StatCard(label: 'Storage', value: '${s.storageUsedGb.toStringAsFixed(0)} GB', icon: Icons.storage, detail: '${(diskPct * 100).clamp(0, 100).toStringAsFixed(0)}% used'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 5 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .98,
            children: [
              _quickAction(context, Icons.cast_connected_rounded, 'Remote', () => _openRemote(context)),
              _quickAction(context, Icons.radar_rounded, 'Radar Scan', () => _run(context, 'radarai_scan')),
              _quickAction(context, Icons.lock_outline_rounded, 'Lock', () => _run(context, 'lock')),
              _quickAction(context, Icons.bedtime_outlined, 'Sleep', () => _run(context, 'sleep')),
              _quickAction(
                context,
                Icons.system_update_alt_rounded,
                s.updateAvailable ? 'Update PC' : 'Check Update',
                () => _run(context, s.updateAvailable ? 'update_install' : 'update_check'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(s.updateAvailable ? Icons.system_update_alt : Icons.check_circle, color: s.updateAvailable ? MechTheme.warning : MechTheme.success),
              title: Text(s.updateAvailable ? 'MechOS update available' : 'MechOS is up to date', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(s.updateAvailable ? 'Tap Update PC in Quick Actions to start the system update.' : 'Companion will notify you when a new system update is detected.'),
              trailing: s.updateAvailable
                  ? FilledButton(
                      onPressed: () => _run(context, 'update_install'),
                      child: const Text('Update'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Hardware', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),
            _row('CPU', s.cpu), _row('GPU', s.gpu), _row('Kernel', s.kernel),
          ]))),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: MechTheme.glow, size: 28),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ),
        ),
      );

  Widget _row(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 70, child: Text(k, style: const TextStyle(color: MechTheme.subtle))), Expanded(child: Text(v))]));
}
