import 'package:flutter/material.dart';
import '../theme.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: (danger ? MechTheme.danger : MechTheme.primary).withValues(alpha: .15),
            child: Icon(icon, color: danger ? MechTheme.danger : MechTheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, style: const TextStyle(color: MechTheme.subtle)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
