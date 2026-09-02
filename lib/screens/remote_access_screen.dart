import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class RemoteAccessScreen extends StatefulWidget {
  const RemoteAccessScreen({super.key, required this.state});
  final AppState state;

  @override
  State<RemoteAccessScreen> createState() => _RemoteAccessScreenState();
}

class _RemoteAccessScreenState extends State<RemoteAccessScreen> {
  late final TextEditingController remoteUrl;
  String? result;
  bool testing = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    remoteUrl = TextEditingController(text: widget.state.connection?.remoteUrl ?? '');
  }

  @override
  void dispose() {
    remoteUrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (remoteUrl.text.trim().isEmpty) {
      setState(() => result = 'Enter a private remote bridge address first.');
      return;
    }
    setState(() {
      testing = true;
      result = null;
    });
    try {
      final message = await widget.state.testRemoteUrl(remoteUrl.text.trim());
      if (mounted) setState(() => result = message);
    } catch (e) {
      if (mounted) setState(() => result = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      saving = true;
      result = null;
    });
    try {
      await widget.state.saveRemoteUrl(remoteUrl.text.trim());
      if (mounted) setState(() => result = remoteUrl.text.trim().isEmpty ? 'Remote Access address removed.' : 'Remote Access address saved.');
    } catch (e) {
      if (mounted) setState(() => result = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final routeColor = state.connectionRoute == ConnectionRoute.remote
        ? MechTheme.success
        : state.connectionRoute == ConnectionRoute.local
            ? MechTheme.primary
            : state.connectionRoute == ConnectionRoute.offline
                ? MechTheme.danger
                : MechTheme.warning;
    return Scaffold(
      appBar: AppBar(title: const Text('Remote Access')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(state.isRemote ? Icons.public : Icons.lan, color: routeColor),
              title: Text('${state.connectionRouteLabel} connection', style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(state.activeBaseUrl ?? 'No active route'),
              trailing: IconButton(onPressed: state.loading ? null : state.refresh, icon: const Icon(Icons.refresh)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Private remote route', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Use a Tailscale or WireGuard address for your MechOS machine. The app tries the local address first and automatically falls back to this private remote route when you are away from home.',
            style: TextStyle(color: MechTheme.subtle),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: remoteUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Remote MechOS Bridge address',
              prefixIcon: Icon(Icons.vpn_lock_outlined),
              hintText: 'http://100.x.y.z:47831 or https://host.ts.net:47831',
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: testing ? null : _test,
                icon: testing ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check),
                label: const Text('Test'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
          ]),
          if (result != null) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(result!))),
          ],
          const SizedBox(height: 18),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: MechTheme.success),
              title: Text('No router port forwarding', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('Remote HTTP is accepted only for private/Tailscale address ranges. Public hostnames must use HTTPS. The bridge bearer token is still required.'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: Icon(Icons.notifications_active_outlined),
              title: Text('Away-from-home alerts', style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text('Live hardware and RadarAI alerts work over the private remote route while the app is open. The repository also includes a provider-neutral background push dispatcher; APNs/FCM credentials remain external to source control.'),
            ),
          ),
        ],
      ),
    );
  }
}
