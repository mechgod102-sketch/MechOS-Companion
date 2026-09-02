import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/companion_features.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.state});
  final AppState state;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(widget.state.loadNotifications);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => widget.state.loadNotifications());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MechOS Notifications')),
        body: RefreshIndicator(
          onRefresh: widget.state.loadNotifications,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: const ListTile(
                  leading: Icon(Icons.notifications_active_outlined, color: MechTheme.primary),
                  title: Text('Live hardware + RadarAI alert feed'),
                  subtitle: Text('The companion refreshes authenticated alerts while it is active. The bridge API is ready for a future APNs/FCM background push provider without exposing shell access.'),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.state.notifications.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(children: [
                      Icon(Icons.verified_user_outlined, size: 42, color: MechTheme.success),
                      SizedBox(height: 10),
                      Text('No active hardware alerts', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 5),
                      Text('RadarAI and MechOS hardware checks have not reported a current warning.', textAlign: TextAlign.center, style: TextStyle(color: MechTheme.subtle)),
                    ]),
                  ),
                )
              else
                for (final notice in widget.state.notifications) ...[
                  _NoticeCard(notice: notice),
                  const SizedBox(height: 10),
                ],
              if (widget.state.error != null) Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
            ],
          ),
        ),
      );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});
  final CompanionNotification notice;

  Color get color {
    switch (notice.severity.toLowerCase()) {
      case 'critical':
      case 'error':
        return MechTheme.danger;
      case 'warning':
        return MechTheme.warning;
      default:
        return MechTheme.primary;
    }
  }

  IconData get icon {
    switch (notice.severity.toLowerCase()) {
      case 'critical':
      case 'error':
        return Icons.report_gmailerrorred;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 5),
                Text(notice.detail, style: const TextStyle(color: MechTheme.subtle)),
                const SizedBox(height: 8),
                Text('${notice.source} • ${_date(notice.createdAt)}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      );

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
