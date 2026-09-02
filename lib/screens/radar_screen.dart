import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class RadarScreen extends StatelessWidget {
  const RadarScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('RadarAI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('System health and issue reporting from your paired MechOS device.', style: TextStyle(color: MechTheme.subtle)),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          try { messenger.showSnackBar(SnackBar(content: Text(await state.runAction('radarai_scan')))); }
          catch (e) { messenger.showSnackBar(SnackBar(content: Text('$e'))); }
        }, icon: const Icon(Icons.radar), label: const Text('Run quick scan')),
        const SizedBox(height: 16),
        if (state.alerts.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(22), child: Center(child: Text('No active RadarAI alerts.'))))
        else
          ...state.alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(child: ListTile(
                  leading: Icon(a.severity == 'critical' ? Icons.error : a.severity == 'warning' ? Icons.warning_amber : Icons.info_outline, color: a.severity == 'critical' ? MechTheme.danger : a.severity == 'warning' ? MechTheme.warning : MechTheme.primary),
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(a.detail),
                )),
              )),
      ]);
}
