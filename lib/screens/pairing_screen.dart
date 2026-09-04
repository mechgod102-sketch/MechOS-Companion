import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/discovered_device.dart';
import '../services/device_discovery_service.dart';
import '../theme.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.state});
  final AppState state;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final url = TextEditingController(text: 'http://mechos.local:47831');
  final code = TextEditingController();
  final name = TextEditingController(text: 'My phone');
  final discovery = DeviceDiscoveryService();
  List<DiscoveredDevice> devices = const [];
  bool scanning = false;
  String? discoveryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    url.dispose();
    code.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (scanning) return;
    setState(() {
      scanning = true;
      discoveryError = null;
    });
    try {
      final result = await discovery.discover();
      if (!mounted) return;
      setState(() {
        devices = result;
        if (result.isNotEmpty) url.text = result.first.baseUrl;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => discoveryError = 'Auto-detect could not scan this network. You can still enter the PC address manually.');
    } finally {
      if (mounted) setState(() => scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF142A52), Color(0xFF0A1122)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: MechTheme.glow.withValues(alpha: .45)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.precision_manufacturing_rounded, size: 72, color: MechTheme.glow),
                          SizedBox(height: 14),
                          Text('MechOS Companion', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                          SizedBox(height: 6),
                          Text('Control • Monitor • Download • Anywhere', textAlign: TextAlign.center, style: TextStyle(color: MechTheme.subtle)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Find your MechOS PC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                      SizedBox(height: 3),
                                      Text('Nearby computers are detected automatically over your local network.', style: TextStyle(color: MechTheme.subtle, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: scanning ? null : _scan,
                                  icon: scanning
                                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                            if (devices.isEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: MechTheme.panel2, borderRadius: BorderRadius.circular(14)),
                                child: Row(
                                  children: [
                                    Icon(scanning ? Icons.radar_rounded : Icons.desktop_windows_outlined, color: MechTheme.glow),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(scanning ? 'Scanning for MechOS computers…' : 'No MechOS PC detected yet.', style: const TextStyle(color: MechTheme.subtle))),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              ...devices.map((device) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: url.text == device.baseUrl ? MechTheme.primary.withValues(alpha: .18) : MechTheme.panel2,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        onTap: () => setState(() => url.text = device.baseUrl),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.computer_rounded, color: MechTheme.glow),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(device.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                                    Text(device.baseUrl, style: const TextStyle(color: MechTheme.subtle, fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.chevron_right_rounded),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),
                            ],
                            if (discoveryError != null) ...[
                              const SizedBox(height: 8),
                              Text(discoveryError!, style: const TextStyle(color: MechTheme.warning, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: url,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'MechOS PC address', prefixIcon: Icon(Icons.lan_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(labelText: '6-digit pairing code', prefixIcon: Icon(Icons.password_rounded), counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'This phone name', prefixIcon: Icon(Icons.phone_android_rounded)),
                    ),
                    if (widget.state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: widget.state.loading
                          ? null
                          : () => widget.state.pair(
                                baseUrl: url.text.trim(),
                                code: code.text.trim(),
                                mobileName: name.text.trim(),
                              ),
                      icon: widget.state.loading
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.link_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Pair with MechOS'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: widget.state.useDemo,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview Demo'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'After pairing on Wi-Fi, MechOS Anywhere can automatically fall back to your configured remote relay when your phone is on cellular data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MechTheme.subtle, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
