import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import 'controls_screen.dart';
import 'optimization_report_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tools', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Tune, optimize, and control your MechOS PC from one place.', style: TextStyle(color: MechTheme.subtle)),
          const SizedBox(height: 18),
          _tool(
            context,
            icon: Icons.speed_rounded,
            title: 'Performance & Optimization',
            detail: 'Scan system health, review bottlenecks, and get recommended fixes.',
            onTap: () => _open(context, 'Optimize', OptimizationReportScreen(state: state)),
          ),
          const SizedBox(height: 12),
          _tool(
            context,
            icon: Icons.tune_rounded,
            title: 'System Controls',
            detail: 'Switch sessions, check updates, run RadarAI, restart, or shut down.',
            onTap: () => _open(context, 'System Controls', ControlsScreen(state: state)),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: MechTheme.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connection Security', style: TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${state.connectionMode} • paired-device token required', style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _tool(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) =>
      Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: MechTheme.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: MechTheme.glow),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                      const SizedBox(height: 5),
                      Text(detail, style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: MechTheme.subtle),
              ],
            ),
          ),
        ),
      );

  void _open(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(child: child),
        ),
      ),
    );
  }
}
