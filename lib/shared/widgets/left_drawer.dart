import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/day/presentation/profile_screen.dart';

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
            _ProfileSection(onTap: () => _navProfile(context)),

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
                    onTap: () => _comingSoon(context, 'Categories'),
                  ),
                  _DrawerItem(
                    icon: Icons.schedule_rounded,
                    color: AppColors.orange,
                    label: 'Working Hours',
                    subtitle: 'Set your working hours',
                    onTap: () => _comingSoon(context, 'Working Hours'),
                  ),
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    color: AppColors.teal,
                    label: 'Focus Settings',
                    subtitle: 'Pomodoro, focus modes etc.',
                    onTap: () => _comingSoon(context, 'Focus Settings'),
                  ),
                  const _Divider(),
                  _SectionHeader('DATA & SYNC'),
                  _DrawerItem(
                    icon: Icons.cloud_sync_rounded,
                    color: AppColors.teal,
                    label: 'Backup & Sync',
                    subtitle: 'Keep your data safe',
                    onTap: () => _comingSoon(context, 'Backup & Sync'),
                  ),
                  _DrawerItem(
                    icon: Icons.import_export_rounded,
                    color: AppColors.textSecondary,
                    label: 'Import & Export',
                    onTap: () => _comingSoon(context, 'Import & Export'),
                  ),
                  const _Divider(),
                  _SectionHeader('OTHER'),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    color: AppColors.textSecondary,
                    label: 'Settings',
                    onTap: () => _showSettings(context),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.textSecondary,
                    label: 'Help & Feedback',
                    onTap: () => _showHelp(context),
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    label: 'About Cortex',
                    onTap: () => _showAbout(context),
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
    context.push(route);
  }

  void _navProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _SettingsSheet(),
    );
  }

  void _showHelp(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _HelpSheet(),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AboutSheet(),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileSection({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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

// ── Settings Sheet ─────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          const SizedBox(height: 20),
          const Text('Settings',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            color: AppColors.primary,
            label: 'Change PIN',
            subtitle: 'Update your app lock PIN',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('PIN change coming soon'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const Divider(color: AppColors.divider, thickness: 0.5, height: 1, indent: 52),
          _SettingsTile(
            icon: Icons.fingerprint_rounded,
            color: AppColors.teal,
            label: 'Biometric Login',
            subtitle: 'Use fingerprint or face ID',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Biometric settings coming soon'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const Divider(color: AppColors.divider, thickness: 0.5, height: 1, indent: 52),
          _SettingsTile(
            icon: Icons.palette_outlined,
            color: AppColors.orange,
            label: 'Appearance',
            subtitle: 'Theme, colors & display',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Appearance settings coming soon'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.border, size: 16),
      onTap: onTap,
    );
  }
}

// ── Help Sheet ─────────────────────────────────────────────────────────────

class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sheetHandle(),
          const SizedBox(height: 20),
          const Text('Help & Feedback',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _HelpTile(
            icon: Icons.email_outlined,
            label: 'Send Feedback',
            subtitle: 'sharats.sankar@cognizant.com',
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(
                  const ClipboardData(text: 'sharats.sankar@cognizant.com'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Email copied to clipboard'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const Divider(color: AppColors.divider, thickness: 0.5, height: 1, indent: 48),
          _HelpTile(
            icon: Icons.bug_report_outlined,
            label: 'Report a Bug',
            subtitle: 'Let us know what went wrong',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Bug reporting coming soon'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
          const Divider(color: AppColors.divider, thickness: 0.5, height: 1, indent: 48),
          _HelpTile(
            icon: Icons.menu_book_outlined,
            label: 'Getting Started Guide',
            subtitle: 'Learn how to use CORTEX',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Guide coming soon'),
                    behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      onTap: onTap,
    );
  }
}

// ── About Sheet ────────────────────────────────────────────────────────────

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sheetHandle(),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('CORTEX',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5)),
          const SizedBox(height: 4),
          const Text('Your intelligent second brain',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Version 1.0.0',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, thickness: 0.5),
          const SizedBox(height: 12),
          const Text(
            'CORTEX is a personal productivity app built to help you\nplan your day, track goals, and capture everything that matters.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text('Built with Flutter  ·  Powered by Drift',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

Widget _sheetHandle() => Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2)),
      ),
    );
