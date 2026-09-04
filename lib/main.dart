import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/pairing_screen.dart';
import 'services/background_monitor.dart';
import 'services/notification_service.dart';
import 'services/secure_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
  try {
    await initializeBackgroundMonitoring();
  } catch (e) {
    debugPrint('Background monitoring setup unavailable: $e');
  }

  final state = AppState(SecureStore());
  NotificationService.onAction = state.handleNotificationAction;
  await state.restore();

  final pendingAction = await NotificationService.consumePendingAction();
  if (pendingAction != null) {
    await state.handleNotificationAction(pendingAction);
  }

  runApp(MechOSCompanionApp(state: state));
}

class MechOSCompanionApp extends StatefulWidget {
  const MechOSCompanionApp({super.key, required this.state});
  final AppState state;
  @override State<MechOSCompanionApp> createState() => _MechOSCompanionAppState();
}

class _MechOSCompanionAppState extends State<MechOSCompanionApp> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_changed);
  }

  @override
  void dispose() {
    widget.state.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MechOS Companion',
        debugShowCheckedModeBanner: false,
        theme: MechTheme.dark(),
        home: widget.state.isConnected
            ? HomeShell(state: widget.state)
            : PairingScreen(state: widget.state),
      );
}
