import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/companion_features.dart';
import '../theme.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key, required this.state});
  final AppState state;

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final List<PerformanceSample> _history = [];
  Timer? _timer;
  bool _polling = false;
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_poll);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final sample = await widget.state.fetchPerformance(demoPhase: _phase++);
      if (!mounted) return;
      setState(() {
        _history.add(sample);
        if (_history.length > 30) _history.removeAt(0);
      });
      if (_phase % 4 == 1) await widget.state.loadUpdateProgress();
    } catch (_) {
      if (mounted) setState(() {});
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sample = _history.isNotEmpty ? _history.last : widget.state.latestPerformance;
    final update = widget.state.updateProgress;
    return RefreshIndicator(
      onRefresh: _poll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            const Expanded(child: Text('Live Performance', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            IconButton(onPressed: _polling ? null : _poll, icon: const Icon(Icons.refresh)),
          ]),
          const SizedBox(height: 4),
          const Text('Live MechOS telemetry sampled through the authenticated bridge.', style: TextStyle(color: MechTheme.subtle)),
          const SizedBox(height: 16),
          if (sample == null)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
          else ...[
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _MetricCard(label: 'CPU', value: sample.cpuPercent, suffix: '%', icon: Icons.memory),
                _MetricCard(label: 'GPU', value: sample.gpuPercent, suffix: '%', icon: Icons.developer_board),
                _MetricCard(label: 'RAM', value: sample.ramPercent, suffix: '%', icon: Icons.storage),
                _MetricCard(label: 'TEMP', value: sample.temperatureC, suffix: '°C', icon: Icons.thermostat),
              ],
            ),
            const SizedBox(height: 14),
            _GraphCard(
              title: 'CPU / GPU / RAM history',
              history: _history,
              series: [
                _Series('CPU', (s) => s.cpuPercent, MechTheme.primary),
                _Series('GPU', (s) => s.gpuPercent, MechTheme.warning),
                _Series('RAM', (s) => s.ramPercent, MechTheme.success),
              ],
              minValue: 0,
              maxValue: 100,
            ),
            const SizedBox(height: 12),
            _GraphCard(
              title: 'Temperature history',
              history: _history,
              series: [_Series('TEMP', (s) => s.temperatureC, MechTheme.danger)],
              minValue: 30,
              maxValue: 105,
            ),
          ],
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [Icon(Icons.system_update_alt), SizedBox(width: 10), Text('MechOS Update Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
                const SizedBox(height: 12),
                if (update == null)
                  const Text('Waiting for updater status…', style: TextStyle(color: MechTheme.subtle))
                else ...[
                  Row(children: [
                    Expanded(child: Text(update.phase.isEmpty ? update.state : update.phase, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text('${update.progress.toStringAsFixed(0)}%'),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: update.progress / 100),
                  if (update.message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(update.message, style: const TextStyle(color: MechTheme.subtle)),
                  ],
                ],
              ]),
            ),
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Text(widget.state.error!, style: const TextStyle(color: MechTheme.danger)),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.suffix, required this.icon});
  final String label;
  final double? value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [Icon(icon, size: 20, color: MechTheme.primary), const SizedBox(width: 8), Text(label, style: const TextStyle(color: MechTheme.subtle, fontWeight: FontWeight.w700))]),
            const SizedBox(height: 8),
            Text(value == null ? 'N/A' : '${value!.toStringAsFixed(0)}$suffix', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ]),
        ),
      );
}

class _Series {
  const _Series(this.label, this.value, this.color);
  final String label;
  final double? Function(PerformanceSample sample) value;
  final Color color;
}

class _GraphCard extends StatelessWidget {
  const _GraphCard({required this.title, required this.history, required this.series, required this.minValue, required this.maxValue});
  final String title;
  final List<PerformanceSample> history;
  final List<_Series> series;
  final double minValue;
  final double maxValue;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 6, children: [
              for (final item in series)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(item.label, style: const TextStyle(color: MechTheme.subtle, fontSize: 12)),
                ]),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(painter: _TelemetryPainter(history, series, minValue, maxValue)),
            ),
          ]),
        ),
      );
}

class _TelemetryPainter extends CustomPainter {
  _TelemetryPainter(this.history, this.series, this.minValue, this.maxValue);
  final List<PerformanceSample> history;
  final List<_Series> series;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = MechTheme.border..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (history.length < 2) return;
    final range = (maxValue - minValue).abs() < 0.01 ? 1.0 : maxValue - minValue;
    for (final item in series) {
      final path = Path();
      var started = false;
      for (var i = 0; i < history.length; i++) {
        final raw = item.value(history[i]);
        if (raw == null) continue;
        final value = raw.clamp(minValue, maxValue).toDouble();
        final x = size.width * i / (history.length - 1);
        final y = size.height - ((value - minValue) / range * size.height);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      if (started) canvas.drawPath(path, Paint()..color = item.color..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _TelemetryPainter oldDelegate) => true;
}
