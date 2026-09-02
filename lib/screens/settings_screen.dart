import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = state.connection;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Paired device', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 12),
        Text(state.demoMode ? 'Demo Mode' : (c?.deviceName ?? 'Not paired')),
        const SizedBox(height: 4),
        Text(state.demoMode ? 'No network connection' : (c?.baseUrl ?? ''), style: const TextStyle(color: MechTheme.subtle)),
      ]))),
      const SizedBox(height: 12),
      Card(child: const ListTile(leading: Icon(Icons.security), title: Text('Pairing token'), subtitle: Text('Stored in Android Keystore / Apple Keychain through secure storage.'))),
      const SizedBox(height: 12),
      Card(child: const ListTile(leading: Icon(Icons.info_outline), title: Text('MechOS Companion Mobile'), subtitle: Text('Version 0.1.1'))),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: state.disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect device')),
    ]);
  }
}
