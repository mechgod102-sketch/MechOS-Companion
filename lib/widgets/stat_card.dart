import 'package:flutter/material.dart';
import '../theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.detail});
  final String label;
  final String value;
  final IconData icon;
  final String? detail;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: MechTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(color: MechTheme.subtle, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (detail != null) ...[
              const SizedBox(height: 4),
              Text(detail!, style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
            ],
          ]),
        ),
      );
}
