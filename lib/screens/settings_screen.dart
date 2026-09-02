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
          const SizedBox(height: 8),
          const Text('Local', style: TextStyle(color: MechTheme.subtle, fontSize: 12)),
          Text(state.demoMode ? 'No network connection' : (c?.localUrl ?? '')),
          const SizedBox(height: 8),
          const Text('Remote private route', style: TextStyle(color: MechTheme.subtle, fontSize: 12)),
          Text(state.demoMode ? 'Demo' : (c?.remoteUrl ?? 'Not configured')),
          const SizedBox(height: 8),
          Text('Current route: ${state.connectionRouteLabel}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.security), title: Text('Pairing security'), subtitle: Text('The device credential is stored using Android Keystore / Apple Keychain secure storage.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.vpn_lock_outlined), title: Text('Remote Access security'), subtitle: Text('Use a private Tailscale/WireGuard route. Do not expose port 47831 through router port forwarding. Public remote hostnames must use HTTPS.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.notifications_outlined), title: Text('Background notifications'), subtitle: Text('The repository includes a provider-neutral push dispatcher. APNs/FCM provider credentials and device registration remain external to the public source repository.'))),
        const SizedBox(height: 12),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('MechOS Companion Mobile'), subtitle: Text('Version 0.1.3'))),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: state.disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect this phone')),
      ]),
    );
  }
}
