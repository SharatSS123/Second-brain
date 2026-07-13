import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'left_drawer.dart';
import 'live_activity_banner.dart';

final mainScaffoldKey = GlobalKey<ScaffoldState>();

const _morePaths = [
  '/tasks',
  '/learning',
  '/entertainment',
  '/knowledge',
  '/books',
  '/planner',
  '/lists',
];

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _NavTab(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        path: '/dashboard'),
    _NavTab(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
        label: 'Day',
        path: '/day'),
    _NavTab(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Notes',
        path: '/notes'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (idx >= 0) return idx;
    if (_morePaths.any((p) => location.startsWith(p))) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final location = GoRouterState.of(context).uri.path;
    final showBanner = location != '/day' && location != '/dashboard';

    return Scaffold(
      key: mainScaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: const LeftDrawer(),
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBanner) const LiveActivityBanner(),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5)),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (i) {
                if (i == 3) {
                  _showMoreSheet(context);
                } else {
                  context.go(_tabs[i].path);
                }
              },
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.15),
              destinations: [
                ..._tabs.map((tab) => NavigationDestination(
                      icon: Icon(tab.icon, color: AppColors.textSecondary),
                      selectedIcon:
                          Icon(tab.activeIcon, color: AppColors.primary),
                      label: tab.label,
                    )),
                const NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined,
                      color: AppColors.textSecondary),
                  selectedIcon:
                      Icon(Icons.grid_view_rounded, color: AppColors.primary),
                  label: 'More',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _MoreSheet(
        onTap: (path) {
          Navigator.pop(sheetCtx);
          context.push(path);
        },
      ),
    );
  }
}

// ── More bottom sheet ──────────────────────────────────────────────────────

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.onTap});
  final void Function(String path) onTap;

  static const _items = [
    _MoreItem(
      icon: Icons.check_circle_outline_rounded,
      label: 'Tasks',
      color: AppColors.green,
      path: '/tasks',
    ),
    _MoreItem(
      icon: Icons.school_rounded,
      label: 'Learn',
      color: AppColors.amber,
      path: '/learning',
    ),
    _MoreItem(
      icon: Icons.movie_rounded,
      label: 'Watch',
      color: AppColors.blue,
      path: '/entertainment',
    ),
    _MoreItem(
      icon: Icons.menu_book_rounded,
      label: 'Books',
      color: Color(0xFF22C55E),
      path: '/books',
    ),
    _MoreItem(
      icon: Icons.folder_rounded,
      label: 'Vault',
      color: AppColors.orange,
      path: '/knowledge',
    ),
    _MoreItem(
      icon: Icons.format_list_bulleted_rounded,
      label: 'Lists',
      color: AppColors.teal,
      path: '/lists',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 48 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'More',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Feature grid — Wrap with 4 per row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _items
                .map((item) => _MoreTile(item: item, onTap: onTap))
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item, required this.onTap});
  final _MoreItem item;
  final void Function(String path) onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 20 padding left/right (40) and 3 gaps of 16 (48) between 4 items
    final itemWidth = (screenWidth - 40 - 48) / 4;

    return GestureDetector(
      onTap: () => onTap(item.path),
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: item.color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final Color color;
  final String path;
  const _MoreItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.path,
  });
}

// ── Nav tab model ──────────────────────────────────────────────────────────

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
