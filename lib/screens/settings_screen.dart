import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final c = state.connection;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Paired MechOS system', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 12),
          Text(state.demoMode ? 'Demo Mode' : (c?.deviceName ?? 'Not paired')),
          const SizedBox(height: 4),
          Text(state.demoMode ? 'No network connection' : (c?.baseUrl ?? ''), style: const TextStyle(color: MechTheme.subtle)),
        ]))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.security), title: Text('Pairing security'), subtitle: Text('The device credential is stored using Android Keystore / Apple Keychain secure storage.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.notifications_outlined), title: Text('Notifications'), subtitle: Text('Hardware and RadarAI alerts refresh live while the app is active. Background APNs/FCM delivery can be enabled later by connecting a push provider.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('MechOS Companion Mobile'), subtitle: Text('Version 0.1.2'))),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: state.disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect this phone')),
      ]),
    );
  }
}
