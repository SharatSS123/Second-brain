import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../providers/planner_providers.dart';
import '../../utils/planner_utils.dart';
import '../activity_detail_screen.dart';

class UpcomingTab extends ConsumerStatefulWidget {
  const UpcomingTab({super.key});

  @override
  ConsumerState<UpcomingTab> createState() => _UpcomingTabState();
}

class _UpcomingTabState extends ConsumerState<UpcomingTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tc,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              _UpcomingList(),
              _CompletedList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _UpcomingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingActivitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_rounded,
                    color: AppColors.border, size: 48),
                SizedBox(height: 12),
                Text('No upcoming activities',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final grouped = _groupByDate(activities);
        final dates = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: dates.length,
          itemBuilder: (_, i) {
            final date = dates[i];
            final items = grouped[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _dateHeader(date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...items.map((a) => _UpcomingItem(activity: a)),
              ],
            );
          },
        );
      },
    );
  }

  Map<DateTime, List<PlannerActivity>> _groupByDate(
      List<PlannerActivity> list) {
    final Map<DateTime, List<PlannerActivity>> map = {};
    for (final a in list) {
      final d = dateOnly(a.date);
      map.putIfAbsent(d, () => []).add(a);
    }
    return map;
  }

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    final tomorrow = dateOnly(now.add(const Duration(days: 1)));
    if (dateOnly(date) == tomorrow) {
      return 'Tomorrow  •  ${DateFormat('EEE, MMM d').format(date)}';
    }
    return DateFormat('EEE, MMM d').format(date);
  }
}

class _CompletedList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedActivitiesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
      data: (activities) {
        if (activities.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.border, size: 48),
                SizedBox(height: 12),
                Text('No completed activities',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: activities.length,
          itemBuilder: (_, i) =>
              _UpcomingItem(activity: activities[i], showDate: true),
        );
      },
    );
  }
}

class _UpcomingItem extends StatelessWidget {
  const _UpcomingItem({required this.activity, this.showDate = false});
  final PlannerActivity activity;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActivityDetailScreen(activity: activity)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTime(activity.startTime),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  if (showDate)
                    Text(
                      DateFormat('MMM d').format(activity.date),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      color: activity.isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: activity.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    activity.category,
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              displayDuration(activity.startTime, activity.endTime),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
