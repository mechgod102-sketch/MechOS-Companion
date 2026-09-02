import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(widget.state.loadPairedDevices);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Paired Mobile Devices')),
        body: RefreshIndicator(
          onRefresh: widget.state.loadPairedDevices,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: ListTile(
                  leading: Icon(Icons.devices, color: MechTheme.primary),
                  title: Text('Connected companion devices'),
                  subtitle: Text('Review phones and tablets paired with the current MechOS system.'),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.state.pairedMobileDevices.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No paired mobile devices were reported.', textAlign: TextAlign.center)))
              else
                for (final device in widget.state.pairedMobileDevices) ...[
                  Card(
                    child: ListTile(
                      leading: Icon(device.current ? Icons.phone_android : Icons.devices_other, color: device.current ? MechTheme.success : MechTheme.primary),
                      title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${device.current ? 'This phone • ' : ''}Paired ${_date(device.pairedAt)}\nDevice ID ${device.id}'),
                      isThreeLine: true,
                      trailing: device.current ? const Chip(label: Text('Current')) : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              if (widget.state.error != null) Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
            ],
          ),
        ),
      );

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
