import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';

class CalendarPickerScreen extends ConsumerStatefulWidget {
  const CalendarPickerScreen({super.key});

  @override
  ConsumerState<CalendarPickerScreen> createState() =>
      _CalendarPickerScreenState();
}

class _CalendarPickerScreenState extends ConsumerState<CalendarPickerScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final d = ref.read(selectedDateProvider);
    _selected = d;
    _month = DateTime(d.year, d.month, 1);
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1, 1));

  @override
  Widget build(BuildContext context) {
    final monthActivities = ref.watch(monthActivitiesProvider).value ?? [];
    final activeDates =
        monthActivities.map((a) => dateOnly(a.date)).toSet();

    // Activities for selected date
    final dayActivities = monthActivities
        .where((a) => dateOnly(a.date) == dateOnly(_selected))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(_month),
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _prevMonth,
            color: AppColors.textSecondary,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _nextMonth,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Day labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _MonthGrid(
              year: _month.year,
              month: _month.month,
              selectedDate: _selected,
              activeDates: activeDates,
              onDateTap: (d) => setState(() => _selected = d),
            ),
          ),

          const Divider(
              color: AppColors.divider, thickness: 0.5, height: 24),

          // Selected date label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d').format(_selected),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayActivities.length} activit${dayActivities.length == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Day's activity list
          Expanded(
            child: dayActivities.isEmpty
                ? const Center(
                    child: Text('No activities',
                        style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: dayActivities.length,
                    itemBuilder: (_, i) =>
                        _CalendarActivityTile(activity: dayActivities[i]),
                  ),
          ),

          // Go to this day button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = _selected;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go to This Day',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
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
            final idx = row * 7 + col;
            final dayNum = idx - _firstWeekday + 1;
            if (dayNum < 1 || dayNum > _daysInMonth) {
              return const Expanded(child: SizedBox(height: 48));
            }
            final date = DateTime(year, month, dayNum);
            final isSelected = dateOnly(date) == dateOnly(selectedDate);
            final isToday = dateOnly(date) == dateOnly(DateTime.now());
            final hasActs = activeDates.contains(dateOnly(date));

            return Expanded(
              child: GestureDetector(
                onTap: () => onDateTap(date),
                child: Container(
                  height: 48,
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
                      Text('$dayNum',
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
                          )),
                      if (hasActs)
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

class _CalendarActivityTile extends StatelessWidget {
  const _CalendarActivityTile({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(displayTime(activity.startTime),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(activity.title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.more_vert_rounded,
              color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}
