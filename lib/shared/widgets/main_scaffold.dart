import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', path: '/dashboard'),
    _NavTab(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: 'Tasks', path: '/tasks'),
    _NavTab(icon: Icons.note_alt_outlined, activeIcon: Icons.note_alt, label: 'Notes', path: '/notes'),
    _NavTab(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Learn', path: '/learning'),
    _NavTab(icon: Icons.movie_outlined, activeIcon: Icons.movie, label: 'Watch', path: '/entertainment'),
    _NavTab(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Vault', path: '/knowledge'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon),
          selectedIcon: Icon(tab.activeIcon),
          label: tab.label,
        )).toList(),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
