import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('More',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Features'),
          _MoreTile(
            icon: Icons.check_circle_rounded,
            color: AppColors.primary,
            label: 'Tasks',
            subtitle: 'Manage your to-do list',
            onTap: () => context.push('/tasks'),
          ),
          _MoreTile(
            icon: Icons.movie_rounded,
            color: AppColors.blue,
            label: 'Watch',
            subtitle: 'Movies & series watchlist',
            onTap: () => context.push('/entertainment'),
          ),
          _MoreTile(
            icon: Icons.folder_rounded,
            color: AppColors.amber,
            label: 'Knowledge Vault',
            subtitle: 'Save links, docs & resources',
            onTap: () => context.push('/knowledge'),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Settings'),
          _MoreTile(
            icon: Icons.person_rounded,
            color: AppColors.teal,
            label: 'Profile',
            subtitle: 'Your account & preferences',
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.notifications_rounded,
            color: AppColors.orange,
            label: 'Notifications',
            subtitle: 'Reminders & alerts',
            onTap: () {},
          ),
          _MoreTile(
            icon: Icons.security_rounded,
            color: AppColors.green,
            label: 'Security',
            subtitle: 'PIN & biometric settings',
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isLast ? 0 : 14),
                topRight: Radius.circular(isLast ? 0 : 14),
                bottomLeft: const Radius.circular(14),
                bottomRight: const Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          )),
                      Text(subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(
              color: AppColors.divider, thickness: 0.5, height: 1,
              indent: 70),
      ],
    );
  }
}
