import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/optimization_report.dart';
import '../services/report_image_service.dart';
import '../services/report_share_service.dart';
import '../theme.dart';

class OptimizationReportScreen extends StatefulWidget {
  const OptimizationReportScreen({super.key, required this.state});
  final AppState state;

  @override
  State<OptimizationReportScreen> createState() => _OptimizationReportScreenState();
}

class _OptimizationReportScreenState extends State<OptimizationReportScreen> {
  final _imageService = ReportImageService();
  final _shareService = ReportShareService();
  ReportImageFormat _format = ReportImageFormat.full;
  Uint8List? _preview;
  String? _imagePath;
  bool _working = false;

  OptimizationReport? get _report => widget.state.optimizationReport;

  Future<void> _scan() async {
    setState(() => _working = true);
    try {
      await widget.state.scanOptimization();
      if (!mounted) return;
      setState(() {
        _preview = null;
        _imagePath = null;
      });
      _snack('Optimization scan complete.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _generate() async {
    final report = _report;
    if (report == null) {
      _snack('Run an optimization scan first.', error: true);
      return;
    }
    setState(() => _working = true);
    try {
      final generated = await _imageService.generate(report, format: _format);
      if (!mounted) return;
      setState(() {
        _preview = generated.bytes;
        _imagePath = generated.path;
      });
      _snack('Report image generated.');
    } catch (e) {
      _snack('Could not generate report: $e', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _save() async {
    if (_imagePath == null) await _generate();
    final path = _imagePath;
    if (path == null) return;
    setState(() => _working = true);
    try {
      await _shareService.saveToGallery(path);
      _snack('Saved to your phone in MechOS Reports.');
    } catch (e) {
      _snack('Could not save image: $e', error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _share() async {
    if (_imagePath == null) await _generate();
    final path = _imagePath;
    final report = _report;
    if (path == null || report == null) return;
    try {
      await _shareService.share(path, report);
    } catch (e) {
      _snack('Could not open share sheet: $e', error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? MechTheme.danger : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return RefreshIndicator(
      onRefresh: _scan,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Optimization Report', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Scan • Analyze • Generate • Share', style: TextStyle(color: MechTheme.subtle)),
                  ],
                ),
              ),
              IconButton(onPressed: _working ? null : _scan, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 16),
          if (report == null) _emptyState() else ...[
            _scoreCard(report),
            const SizedBox(height: 12),
            _metrics(report),
            const SizedBox(height: 12),
            _statusCard(report),
            const SizedBox(height: 12),
            _issuesCard(report),
            const SizedBox(height: 12),
            _fixesCard(report),
          ],
          const SizedBox(height: 16),
          SegmentedButton<ReportImageFormat>(
            segments: const [
              ButtonSegment(value: ReportImageFormat.full, label: Text('Full 1080×1920'), icon: Icon(Icons.article_outlined)),
              ButtonSegment(value: ReportImageFormat.summary, label: Text('Summary 1080×1350'), icon: Icon(Icons.view_agenda_outlined)),
            ],
            selected: {_format},
            onSelectionChanged: _working
                ? null
                : (value) => setState(() {
                      _format = value.first;
                      _preview = null;
                      _imagePath = null;
                    }),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _scan,
            icon: const Icon(Icons.radar),
            label: Text(_working ? 'Working…' : 'Scan Optimization'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _working || report == null ? null : _generate,
            icon: const Icon(Icons.image_outlined),
            label: const Text('Generate Report Image'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _working || report == null ? null : _save,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to Phone'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _working || report == null ? null : _share,
            icon: const Icon(Icons.share),
            label: const Text('Share to Discord'),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 20),
            const Text('Generated preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(_preview!, fit: BoxFit.fitWidth),
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 8),
              Text('Saved app copy: $_imagePath', style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _emptyState() => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.speed, size: 54, color: MechTheme.primary),
              const SizedBox(height: 12),
              const Text('No optimization report yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text(
                'Run a scan to collect performance metrics, RadarAI status, findings, and recommended fixes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MechTheme.subtle),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: _working ? null : _scan, icon: const Icon(Icons.radar), label: const Text('Run Scan')),
            ],
          ),
        ),
      );

  Widget _scoreCard(OptimizationReport r) {
    final scoreColor = r.score >= 85
        ? MechTheme.success
        : r.score >= 70
            ? MechTheme.primary
            : r.score >= 50
                ? MechTheme.warning
                : MechTheme.danger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: r.score / 100, strokeWidth: 10, color: scoreColor, backgroundColor: MechTheme.border),
                  Text('${r.score}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Optimization score ${r.score}/100', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(_scoreLabel(r.score), style: TextStyle(color: scoreColor, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text('Report ${r.reportId}', style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metrics(OptimizationReport r) {
    final data = [
      ('CPU', r.cpuPercent, Icons.memory),
      ('GPU', r.gpuPercent ?? 0, Icons.developer_board_outlined),
      ('RAM', r.ramPercent, Icons.storage_outlined),
      ('Storage', r.storagePercent, Icons.save_outlined),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.7),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final m = data[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(m.$3, color: MechTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$1, style: const TextStyle(color: MechTheme.subtle)),
                      Text('${m.$2.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusCard(OptimizationReport r) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _row('Device', r.hostname),
              _row('MechOS', r.osVersion),
              _row('Session', r.session),
              _row('RadarAI', r.radarAiState),
              if (r.temperatureC != null) _row('Temperature', '${r.temperatureC!.toStringAsFixed(0)}°C'),
            ],
          ),
        ),
      );

  Widget _issuesCard(OptimizationReport r) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Top Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (r.findings.isEmpty)
                const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle, color: MechTheme.success), title: Text('No optimization warnings detected'))
              else
                ...r.findings.take(5).map((f) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(_findingIcon(f.severity), color: _findingColor(f.severity)),
                      title: Text(f.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(f.detail),
                    )),
            ],
          ),
        ),
      );

  Widget _fixesCard(OptimizationReport r) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recommended Fixes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (r.recommendedFixes.isEmpty)
                const Text('No action is required at this time.', style: TextStyle(color: MechTheme.subtle))
              else
                ...r.recommendedFixes.take(6).map((fix) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.check, size: 18, color: MechTheme.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(fix)),
                      ]),
                    )),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: MechTheme.subtle))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  String _scoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 65) return 'Needs attention';
    return 'Optimization recommended';
  }

  IconData _findingIcon(String severity) {
    final s = severity.toLowerCase();
    if (s == 'critical' || s == 'error') return Icons.error_outline;
    if (s == 'warning') return Icons.warning_amber;
    return Icons.info_outline;
  }

  Color _findingColor(String severity) {
    final s = severity.toLowerCase();
    if (s == 'critical' || s == 'error') return MechTheme.danger;
    if (s == 'warning') return MechTheme.warning;
    return MechTheme.primary;
  }
}
