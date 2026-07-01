import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/dashboard'),
    _NavTab(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle_rounded, label: 'Tasks', path: '/tasks'),
    _NavTab(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Notes', path: '/notes'),
    _NavTab(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Learn', path: '/learning'),
    _NavTab(icon: Icons.movie_outlined, activeIcon: Icons.movie_rounded, label: 'Watch', path: '/entertainment'),
    _NavTab(icon: Icons.folder_outlined, activeIcon: Icons.folder_rounded, label: 'Vault', path: '/knowledge'),
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
