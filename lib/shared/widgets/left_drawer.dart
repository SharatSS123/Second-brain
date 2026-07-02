import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LeftDrawer extends StatelessWidget {
  const LeftDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.hub_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CORTEX',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Profile section
            _ProfileSection(),

            const _Divider(),

            // Scroll area for menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _SectionHeader('PLANNER'),
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    color: AppColors.primary,
                    label: 'Manage Templates',
                    subtitle: 'Create and manage your routines',
                    onTap: () => _nav(context, '/templates'),
                  ),
                  _DrawerItem(
                    icon: Icons.label_rounded,
                    color: AppColors.blue,
                    label: 'Categories',
                    subtitle: 'Manage activity categories',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.schedule_rounded,
                    color: AppColors.orange,
                    label: 'Working Hours',
                    subtitle: 'Set your working hours',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    color: AppColors.teal,
                    label: 'Focus Settings',
                    subtitle: 'Pomodoro, focus modes etc.',
                    onTap: () {},
                  ),
                  const _Divider(),
                  _SectionHeader('FEATURES'),
                  _DrawerItem(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                    label: 'Tasks',
                    onTap: () => _nav(context, '/tasks'),
                  ),
                  _DrawerItem(
                    icon: Icons.school_rounded,
                    color: AppColors.amber,
                    label: 'Learn',
                    onTap: () => _nav(context, '/learning'),
                  ),
                  _DrawerItem(
                    icon: Icons.movie_rounded,
                    color: AppColors.blue,
                    label: 'Watch',
                    onTap: () => _nav(context, '/entertainment'),
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.green,
                    label: 'Books',
                    subtitle: 'Reading list & favourites',
                    onTap: () => _nav(context, '/books'),
                  ),
                  _DrawerItem(
                    icon: Icons.folder_rounded,
                    color: AppColors.orange,
                    label: 'Knowledge Vault',
                    onTap: () => _nav(context, '/knowledge'),
                  ),
                  const _Divider(),
                  _SectionHeader('DATA & SYNC'),
                  _DrawerItem(
                    icon: Icons.cloud_sync_rounded,
                    color: AppColors.teal,
                    label: 'Backup & Sync',
                    subtitle: 'Keep your data safe',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.import_export_rounded,
                    color: AppColors.textSecondary,
                    label: 'Import & Export',
                    onTap: () {},
                  ),
                  const _Divider(),
                  _SectionHeader('OTHER'),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    color: AppColors.textSecondary,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.textSecondary,
                    label: 'Help & Feedback',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    label: 'About Cortex',
                    onTap: () {},
                    isLast: true,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }
}

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: const Text(
              'S',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sharat Sankar',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'sharat.sankar@gmail.com',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pro',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          )),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.border, size: 16),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            color: AppColors.divider,
            thickness: 0.5,
            height: 1,
            indent: 70,
          ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        color: AppColors.divider, thickness: 0.5, height: 1);
  }
}
