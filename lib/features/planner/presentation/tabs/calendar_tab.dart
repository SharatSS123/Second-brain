import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/tables/planner_table.dart';
import '../../providers/planner_providers.dart';
import '../../utils/planner_utils.dart';
import '../activity_detail_screen.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime get _selectedDate => ref.read(selectedDateProvider);
  DateTime get _month => ref.read(selectedMonthProvider);

  void _prevMonth() {
    final m = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(m.year, m.month - 1, 1);
  }

  void _nextMonth() {
    final m = ref.read(selectedMonthProvider);
    ref.read(selectedMonthProvider.notifier).state =
        DateTime(m.year, m.month + 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final monthActivities = ref.watch(monthActivitiesProvider).value ?? [];
    final dayActivities = ref.watch(todayActivitiesProvider).value ?? [];

    final activeDates = monthActivities.map((a) => dateOnly(a.date)).toSet();

    return Column(
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _prevMonth,
                color: AppColors.textSecondary,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),

        // Day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _MonthGrid(
            year: month.year,
            month: month.month,
            selectedDate: selectedDate,
            activeDates: activeDates,
            onDateTap: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
        ),

        const Divider(color: AppColors.divider, thickness: 0.5, height: 24),

        // Selected day label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                _dayLabel(selectedDate),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${dayActivities.length} activit${dayActivities.length == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Day's activities
        Expanded(
          child: dayActivities.isEmpty
              ? const Center(
                  child: Text('No activities on this day',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: dayActivities.length,
                  itemBuilder: (_, i) =>
                      _DayActivityItem(activity: dayActivities[i]),
                ),
        ),
      ],
    );
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (dateOnly(date) == dateOnly(now)) return 'Today';
    return DateFormat('EEE, MMM d').format(date);
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.month,
    required this.selectedDate,
    required this.activeDates,
    required this.onDateTap,
  });

  final int year, month;
  final DateTime selectedDate;
  final Set<DateTime> activeDates;
  final ValueChanged<DateTime> onDateTap;

  int get _daysInMonth => DateTime(year, month + 1, 0).day;
  int get _firstWeekday => DateTime(year, month, 1).weekday % 7;

  @override
  Widget build(BuildContext context) {
    final totalCells = _firstWeekday + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - _firstWeekday + 1;
            if (dayNum < 1 || dayNum > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 44));
            }
            final date = DateTime(year, month, dayNum);
            final isSelected = dateOnly(date) == dateOnly(selectedDate);
            final isToday = dateOnly(date) == dateOnly(DateTime.now());
            final hasActivities = activeDates.contains(dateOnly(date));

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateTap(date),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasActivities)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _DayActivityItem extends StatelessWidget {
  const _DayActivityItem({required this.activity});
  final PlannerActivity activity;

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
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
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
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
