import 'package:flutter/material.dart';
import '../app_state.dart';
import 'dashboard_screen.dart';
import 'games_screen.dart';
import 'more_screen.dart';
import 'optimization_report_screen.dart';
import 'performance_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});
  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(state: widget.state),
      PerformanceScreen(state: widget.state),
      OptimizationReportScreen(state: widget.state),
      GamesScreen(state: widget.state),
      MoreScreen(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: screens)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed), label: 'Optimize'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Games'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
