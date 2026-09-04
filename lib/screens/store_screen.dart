import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/download_task.dart';
import '../models/store_item.dart';
import '../theme.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.state});
  final AppState state;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final search = TextEditingController();
  bool creatorOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refreshStore();
    });
    search.addListener(_changed);
  }

  @override
  void dispose() {
    search.removeListener(_changed);
    search.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final items = widget.state.storeItems.where((item) {
      if (creatorOnly && !item.creator) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.state.refreshStore,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MechOS Store', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Browse here. Install directly to your paired PC.', style: TextStyle(color: MechTheme.subtle)),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.state.refreshStore,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _connectionBanner(),
          const SizedBox(height: 14),
          TextField(
            controller: search,
            decoration: const InputDecoration(
              hintText: 'Search games, apps, and creator tools',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Unified Store',
                  icon: Icons.grid_view_rounded,
                  selected: !creatorOnly,
                  onTap: () => setState(() => creatorOnly = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  label: 'Creator Store',
                  icon: Icons.palette_outlined,
                  selected: creatorOnly,
                  onTap: () => setState(() => creatorOnly = true),
                ),
              ),
            ],
          ),
          if (widget.state.downloads.isNotEmpty) ...[
            const SizedBox(height: 18),
            _downloads(widget.state.downloads),
          ],
          const SizedBox(height: 18),
          if (items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 42, color: MechTheme.subtle),
                    const SizedBox(height: 10),
                    Text(
                      widget.state.error ?? 'No matching store items.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MechTheme.subtle),
                    ),
                  ],
                ),
              ),
            )
          else
            ...items.map(_storeCard),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _connectionBanner() {
    final remote = widget.state.connectionMode == 'Remote / Cellular';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10203D), Color(0xFF0C1628)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MechTheme.glow.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(remote ? Icons.public_rounded : Icons.lan_rounded, color: MechTheme.glow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.state.connectionMode, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  remote ? 'Remote installs are being sent through MechOS Anywhere.' : 'Installs are being sent over your local network.',
                  style: const TextStyle(color: MechTheme.subtle, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(StoreItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: MechTheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: MechTheme.primary.withValues(alpha: .25)),
                  ),
                  child: Icon(_iconFor(item.category), color: MechTheme.glow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(item.description, style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _tag(item.category),
                          if (item.creator) _tag('Creator'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: item.installable ? () => _install(item) : null,
                  child: const Text('Install'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _downloads(List<DownloadTask> tasks) {
    final visible = tasks.take(4).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Remote Downloads', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
                TextButton(onPressed: widget.state.refreshDownloads, child: const Text('Refresh')),
              ],
            ),
            const SizedBox(height: 4),
            ...visible.map((task) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_downloadIcon(task), size: 18, color: task.failed ? MechTheme.danger : MechTheme.glow),
                          const SizedBox(width: 8),
                          Expanded(child: Text(task.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text('${task.progress}%', style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: task.progress / 100),
                      if (task.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(task.message, style: const TextStyle(color: MechTheme.subtle, fontSize: 11)),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _install(StoreItem item) async {
    try {
      await widget.state.installStoreItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} was added to the MechOS download queue.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: MechTheme.panel2,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text, style: const TextStyle(color: MechTheme.subtle, fontSize: 10)),
      );

  IconData _iconFor(String category) {
    final value = category.toLowerCase();
    if (value.contains('game')) return Icons.sports_esports_rounded;
    if (value.contains('stream')) return Icons.videocam_rounded;
    if (value.contains('3d')) return Icons.view_in_ar_rounded;
    if (value.contains('art')) return Icons.brush_rounded;
    if (value.contains('communication')) return Icons.forum_rounded;
    return Icons.apps_rounded;
  }

  IconData _downloadIcon(DownloadTask task) {
    if (task.completed) return Icons.check_circle_rounded;
    if (task.failed) return Icons.error_rounded;
    return Icons.downloading_rounded;
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? MechTheme.primary.withValues(alpha: .24) : MechTheme.panel,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? MechTheme.glow : MechTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19),
                const SizedBox(width: 8),
                Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
            ),
          ),
        ),
      );
}
