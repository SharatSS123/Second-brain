import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/planner_providers.dart';
import '../utils/planner_utils.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = categoryStyle(activity.category);
    final repo = ref.read(plannerRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.card,
            onSelected: (v) async {
              if (v == 'delete') {
                await repo.deleteActivity(activity.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              activity.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
          if (activity.description != null && activity.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              activity.description!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          _InfoTile(
            icon: Icons.access_time_rounded,
            label: 'Duration',
            value: displayDuration(activity.startTime, activity.endTime),
          ),
          _InfoTile(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value:
                '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
          ),
          _InfoTile(
            icon: Icons.label_rounded,
            label: 'Category',
            value: activity.category,
            valueColor: color,
          ),
          _InfoTile(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            value: activity.reminderMinutes != null
                ? '${activity.reminderMinutes} min before'
                : 'None',
          ),
          _InfoTile(
            icon: Icons.repeat_rounded,
            label: 'Repeat',
            value: _repeatLabel(activity.repeatType),
            isLast: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await repo.toggleComplete(activity.id, activity.isCompleted);
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(
                activity.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded,
              ),
              label: Text(
                  activity.isCompleted ? 'Mark as Incomplete' : 'Mark as Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    activity.isCompleted ? AppColors.border : AppColors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(String type) => switch (type) {
        'daily' => 'Daily',
        'weekdays' => 'Weekdays',
        'weekends' => 'Weekends',
        'weekly' => 'Weekly',
        _ => 'Does not repeat',
      };
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 16),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
        if (!isLast)
          const Divider(color: AppColors.divider, thickness: 0.5, height: 1),
      ],
    );
  }
}
