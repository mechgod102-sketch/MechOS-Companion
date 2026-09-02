import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/companion_features.dart';
import '../services/developer_bundle_service.dart';
import '../theme.dart';

class DeveloperReportScreen extends StatefulWidget {
  const DeveloperReportScreen({super.key, required this.state});
  final AppState state;

  @override
  State<DeveloperReportScreen> createState() => _DeveloperReportScreenState();
}

class _DeveloperReportScreenState extends State<DeveloperReportScreen> {
  final DeveloperBundleService _service = DeveloperBundleService();
  DeveloperBundle? _bundle;
  DeveloperBundleFiles? _files;
  bool _working = false;

  Future<void> _generate() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final bundle = await widget.state.generateDeveloperBundle();
      final files = await _service.generate(bundle);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _files = files;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Developer report bundle generated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.state.error ?? 'Could not generate developer report')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _share() async {
    final bundle = _bundle;
    final files = _files;
    if (bundle == null || files == null) return;
    await _service.share(bundle, files);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Developer Bug Report')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.bug_report_outlined, color: MechTheme.primary), SizedBox(width: 10), Text('Dev Discord / GitHub bundle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
                  SizedBox(height: 10),
                  Text('Creates a Discord-ready optimization image, structured diagnostic JSON, and a GitHub-ready Markdown issue with sanitized MechOS service logs.', style: TextStyle(color: MechTheme.subtle)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Included', style: TextStyle(fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('• Optimization score and findings\n• CPU/GPU/RAM/storage/temperature snapshot\n• RadarAI alerts\n• Update and session state\n• MechOS Companion Bridge log excerpt\n• RadarAI log excerpt\n• MechOS updater log excerpt', style: TextStyle(color: MechTheme.subtle, height: 1.5)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _working ? null : _generate,
              icon: _working ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.inventory_2_outlined),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Generate Developer Bundle')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _files == null ? null : _share,
              icon: const Icon(Icons.share_outlined),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Share to Discord / GitHub')),
            ),
            if (_bundle != null) ...[
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: MechTheme.success),
                  title: Text(_bundle!.reportId, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text('Score ${_bundle!.optimizationReport.score}/100 • ${_bundle!.optimizationReport.hostname}'),
                ),
              ),
            ],
            if (widget.state.error != null) ...[
              const SizedBox(height: 12),
              Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
            ],
          ],
        ),
      );
}
