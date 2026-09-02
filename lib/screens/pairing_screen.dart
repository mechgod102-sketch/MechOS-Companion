import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.state});
  final AppState state;
  @override State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final url = TextEditingController(text: 'http://mechos.local:47831');
  final code = TextEditingController();
  final name = TextEditingController(text: 'My phone');

  @override
  void dispose() { url.dispose(); code.dispose(); name.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: Icon(Icons.precision_manufacturing, size: 96, color: MechTheme.primary)),
                  const SizedBox(height: 20),
                  const Text('MechOS Companion', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Pair your Android or iPhone with a MechOS PC or Steam Deck.', textAlign: TextAlign.center, style: TextStyle(color: MechTheme.subtle)),
                  const SizedBox(height: 28),
                  TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'MechOS Bridge address', prefixIcon: Icon(Icons.lan))),
                  const SizedBox(height: 12),
                  TextField(controller: code, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(labelText: '6-digit pairing code', prefixIcon: Icon(Icons.password), counterText: '')),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'This phone name', prefixIcon: Icon(Icons.phone_android))),
                  if (widget.state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: widget.state.loading ? null : () => widget.state.pair(baseUrl: url.text.trim(), code: code.text.trim(), mobileName: name.text.trim()),
                    icon: widget.state.loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.link),
                    label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Pair with MechOS')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: widget.state.useDemo, child: const Text('Preview in Demo Mode')),
                  const SizedBox(height: 16),
                  const Text('On MechOS, start the included bridge service and enter the pairing code shown on the computer.', textAlign: TextAlign.center, style: TextStyle(color: MechTheme.subtle, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );
}
