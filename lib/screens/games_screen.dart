import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/companion_features.dart';
import '../theme.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final TextEditingController _search = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(widget.state.loadCompatibility);
    _search.addListener(() => setState(() => query = _search.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.state.games.where((game) {
      if (query.isEmpty) return true;
      return game.name.toLowerCase().contains(query) || game.status.toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.state.loadCompatibility,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const Expanded(child: Text('Game Compatibility', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            IconButton(onPressed: widget.state.loadCompatibility, icon: const Icon(Icons.refresh)),
          ]),
          const SizedBox(height: 4),
          const Text('Compatibility profiles reported by the paired MechOS system.', style: TextStyle(color: MechTheme.subtle)),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search games or status'),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.sports_esports_outlined, size: 40, color: MechTheme.subtle),
                  SizedBox(height: 10),
                  Text('No compatibility entries found', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 5),
                  Text('Update the MechOS compatibility catalog on the paired device, then refresh.', textAlign: TextAlign.center, style: TextStyle(color: MechTheme.subtle)),
                ]),
              ),
            )
          else
            for (final game in filtered) ...[
              _GameCard(game: game),
              const SizedBox(height: 10),
            ],
          if (widget.state.error != null) Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});
  final GameCompatibility game;

  Color _color() {
    final text = game.status.toLowerCase();
    if (text.contains('compatible') || text.contains('available') || text.contains('ready')) return MechTheme.success;
    if (text.contains('broken') || text.contains('blocked') || text.contains('unsupported')) return MechTheme.danger;
    if (text.contains('validation') || text.contains('partial') || text.contains('warning')) return MechTheme.warning;
    return MechTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.sports_esports, color: MechTheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(game.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: color.withAlpha(28), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
              child: Text(game.status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ]),
          if (game.detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(game.detail, style: const TextStyle(color: MechTheme.subtle)),
          ],
          const SizedBox(height: 8),
          Text('Source: ${game.source}', style: const TextStyle(color: MechTheme.subtle, fontSize: 11)),
        ]),
      ),
    );
  }
}
