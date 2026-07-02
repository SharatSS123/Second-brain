import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/dashboard'),
    _NavTab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Planner', path: '/planner'),
    _NavTab(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Notes', path: '/notes'),
    _NavTab(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Learn', path: '/learning'),
    _NavTab(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'More', path: '/more'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (idx >= 0) return idx;
    // Tasks, entertainment, knowledge are sub-screens accessed via More
    if (location.startsWith('/tasks') ||
        location.startsWith('/entertainment') ||
        location.startsWith('/knowledge')) {
      return _tabs.indexWhere((t) => t.path == '/more');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          backgroundColor: Colors.transparent,
          destinations: _tabs
              .map((tab) => NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.activeIcon),
                    label: tab.label,
                  ))
              .toList(),
        ),
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
