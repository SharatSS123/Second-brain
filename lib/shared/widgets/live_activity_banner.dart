import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../features/planner/providers/planner_providers.dart';
import '../../features/planner/utils/planner_utils.dart';

class LiveActivityBanner extends ConsumerStatefulWidget {
  const LiveActivityBanner({super.key});

  @override
  ConsumerState<LiveActivityBanner> createState() => _LiveActivityBannerState();
}

class _LiveActivityBannerState extends ConsumerState<LiveActivityBanner> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(liveActivityProvider);
    return activityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activity) {
        if (activity == null) return const SizedBox.shrink();
        return _ActiveBannerContent(activity: activity);
      },
    );
  }
}

class _ActiveBannerContent extends ConsumerWidget {
  const _ActiveBannerContent({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(activitySubtasksProvider(activity.id));
    final (color, icon) = categoryStyle(activity.category);

    final mLeft = minutesLeft(activity.endTime);
    final s = parseTod(activity.startTime);
    final e = parseTod(activity.endTime);
    final totalMins = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    final elapsed = totalMins - mLeft;
    final timeProgress = totalMins > 0 ? (elapsed / totalMins).clamp(0.0, 1.0) : 0.0;

    return subtasksAsync.when(
      loading: () => _buildBanner(context, color, icon, timeProgress, null, null),
      error: (_, __) => _buildBanner(context, color, icon, timeProgress, null, null),
      data: (subtasks) {
        if (subtasks.isEmpty) {
          return _buildBanner(context, color, icon, timeProgress, null, null);
        }
        final done = subtasks.where((s) => s.isCompleted).length;
        final subtaskProgress = subtasks.isNotEmpty ? done / subtasks.length : 0.0;
        return _buildBanner(context, color, icon, subtaskProgress, done, subtasks.length);
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    Color color,
    IconData icon,
    double progress,
    int? done,
    int? total,
  ) {
    return Material(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 0, color: AppColors.divider, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (done != null && total != null)
                            Text(
                              '$done/$total done',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            )
                          else
                            Text(
                              minutesLeft(activity.endTime) > 0
                                  ? '${minutesLeft(activity.endTime)}m left'
                                  : 'Ending',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
