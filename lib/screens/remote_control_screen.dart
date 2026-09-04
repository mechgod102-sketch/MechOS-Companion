import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/remote_frame.dart';
import '../theme.dart';

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({super.key, required this.state});
  final AppState state;

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final _text = TextEditingController();
  Timer? _timer;
  RemoteFrame? _frame;
  bool _loadingFrame = false;
  bool _streaming = true;
  int _quality = 55;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshFrame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (_streaming) _refreshFrame();
    });
  }

  Future<void> _refreshFrame() async {
    if (_loadingFrame || !mounted) return;
    _loadingFrame = true;
    try {
      final frame = await widget.state.fetchRemoteFrame(quality: _quality);
      if (!mounted) return;
      setState(() {
        _frame = frame;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _loadingFrame = false;
    }
  }

  Future<void> _tap(Offset local, Size boxSize) async {
    final frame = _frame;
    if (frame == null || frame.width <= 0 || frame.height <= 0) return;
    final frameAspect = frame.width / frame.height;
    final boxAspect = boxSize.width / boxSize.height;
    double renderWidth;
    double renderHeight;
    double offsetX = 0;
    double offsetY = 0;
    if (frameAspect > boxAspect) {
      renderWidth = boxSize.width;
      renderHeight = renderWidth / frameAspect;
      offsetY = (boxSize.height - renderHeight) / 2;
    } else {
      renderHeight = boxSize.height;
      renderWidth = renderHeight * frameAspect;
      offsetX = (boxSize.width - renderWidth) / 2;
    }
    final x = ((local.dx - offsetX) / renderWidth).clamp(0.0, 1.0).toDouble();
    final y = ((local.dy - offsetY) / renderHeight).clamp(0.0, 1.0).toDouble();
    await _send('tap', x: x, y: y);
  }

  Future<void> _send(
    String type, {
    double? x,
    double? y,
    double? delta,
    String? key,
    String? text,
  }) async {
    try {
      await widget.state.sendRemoteInput(
        type,
        x: x,
        y: y,
        delta: delta,
        key: key,
        text: text,
      );
      if (mounted && _error != null) setState(() => _error = null);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    final aspect = frame != null && frame.height > 0
        ? math.max(1.0, frame.width / frame.height).toDouble()
        : 16 / 9;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remote Control', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('View and control your MechOS desktop from your phone.', style: TextStyle(color: MechTheme.subtle)),
                ],
              ),
            ),
            IconButton(
              tooltip: _streaming ? 'Pause stream' : 'Resume stream',
              onPressed: () => setState(() => _streaming = !_streaming),
              icon: Icon(_streaming ? Icons.pause_circle_outline : Icons.play_circle_outline),
            ),
            IconButton(
              tooltip: 'Refresh frame',
              onPressed: _refreshFrame,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: aspect,
                child: LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => _tap(
                      details.localPosition,
                      Size(constraints.maxWidth, constraints.maxHeight),
                    ),
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: frame == null
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text('Connecting to PC screen...'),
                              ],
                            )
                          : Image.memory(
                              frame.bytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.low,
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                child: Row(
                  children: [
                    Icon(
                      _streaming ? Icons.circle : Icons.pause_circle,
                      size: 12,
                      color: _streaming ? MechTheme.success : MechTheme.warning,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${widget.state.connectionMode} • tap the screen to move + click',
                        style: const TextStyle(color: MechTheme.subtle, fontSize: 12),
                      ),
                    ),
                    if (_loadingFrame)
                      const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: MechTheme.warning),
              title: const Text('Remote Control unavailable'),
              subtitle: Text(_error!),
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text('Mouse & touch', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _send('click', key: 'left'),
                icon: const Icon(Icons.mouse_outlined),
                label: const Text('Left Click'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _send('click', key: 'right'),
                icon: const Icon(Icons.ads_click_rounded),
                label: const Text('Right Click'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _send('scroll', delta: 3),
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                label: const Text('Scroll Up'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _send('scroll', delta: -3),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                label: const Text('Scroll Down'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Keyboard', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _key('Esc', 'escape'),
            _key('Enter', 'enter'),
            _key('Tab', 'tab'),
            _key('Backspace', 'backspace'),
            _key('Alt + Tab', 'alt_tab'),
            _key('↑', 'up'),
            _key('↓', 'down'),
            _key('←', 'left'),
            _key('→', 'right'),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          minLines: 1,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: 'Type on PC',
            hintText: 'Enter text, then send it to the focused PC app',
            suffixIcon: IconButton(
              tooltip: 'Send text',
              onPressed: () async {
                final value = _text.text;
                if (value.isEmpty) return;
                await _send('text', text: value);
                _text.clear();
              },
              icon: const Icon(Icons.send_rounded),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Stream quality', style: TextStyle(color: MechTheme.subtle)),
            const Spacer(),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 40, label: Text('Low')),
                ButtonSegment(value: 55, label: Text('Auto')),
                ButtonSegment(value: 70, label: Text('High')),
              ],
              selected: {_quality},
              showSelectedIcon: false,
              onSelectionChanged: (values) {
                setState(() => _quality = values.first);
                _refreshFrame();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Card(
          child: ListTile(
            leading: Icon(Icons.security_rounded, color: MechTheme.success),
            title: Text('Paired-device security required'),
            subtitle: Text('Remote screen and input requests use the same authenticated local/MechOS Anywhere connection as the rest of Companion.'),
          ),
        ),
      ],
    );
  }

  Widget _key(String label, String key) => OutlinedButton(
        onPressed: () => _send('key', key: key),
        child: Text(label),
      );
}
