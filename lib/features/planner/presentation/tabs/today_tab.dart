import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/database/app_database.dart';
import '../../providers/planner_providers.dart';
import '../../utils/planner_utils.dart';
import '../activity_detail_screen.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(todayActivitiesProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return activitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
      data: (activities) {
        final now = DateTime.now();
        final active = activities.where((a) =>
            isActiveNow(a.startTime, a.endTime) && !a.isCompleted);
        final currentActivity = active.isNotEmpty ? active.first : null;

        return CustomScrollView(
          slivers: [
            if (currentActivity != null)
              SliverToBoxAdapter(
                child: _NowCard(activity: currentActivity),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  'Timeline',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            activities.isEmpty
                ? SliverFillRemaining(
                    child: _EmptyTimeline(date: selectedDate),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _TimelineItem(
                        activity: activities[i],
                        isFirst: i == 0,
                        isLast: i == activities.length - 1,
                      ),
                      childCount: activities.length,
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    final mLeft = minutesLeft(activity.endTime);
    final tod = parseTod(activity.startTime);
    final todEnd = parseTod(activity.endTime);
    final totalMins =
        (todEnd.hour * 60 + todEnd.minute) - (tod.hour * 60 + tod.minute);
    final elapsed = totalMins - mLeft;
    final progress = totalMins > 0 ? (elapsed / totalMins).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B1D8A),
            AppColors.primary.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                mLeft > 0 ? '$mLeft min left' : 'Ending',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 7),
                    SizedBox(width: 5),
                    Text('In Progress',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends ConsumerWidget {
  const _TimelineItem({
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });
  final PlannerActivity activity;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = categoryStyle(activity.category);
    final isNow = isActiveNow(activity.startTime, activity.endTime);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(activity: activity),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    displayTime(activity.startTime),
                    style: TextStyle(
                      color: isNow
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight:
                          isNow ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  if (!isFirst)
                    Container(
                        width: 1.5,
                        height: 10,
                        color: AppColors.divider),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: isNow ? AppColors.primary : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                          width: 1.5, color: AppColors.divider),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: isNow
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
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
                              '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(plannerRepositoryProvider)
                            .toggleComplete(
                                activity.id, activity.isCompleted),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: activity.isCompleted
                                ? AppColors.green
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activity.isCompleted
                                  ? AppColors.green
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: activity.isCompleted
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final isToday = dateOnly(date) == dateOnly(DateTime.now());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppColors.border, size: 48),
            const SizedBox(height: 16),
            Text(
              isToday ? 'No activities today' : 'No activities on this day',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add an activity',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Activity Sheet ──────────────────────────────────────────────────────

void showAddActivitySheet(BuildContext context, WidgetRef ref,
    {DateTime? forDate}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddActivitySheet(
      initialDate: forDate ?? ref.read(selectedDateProvider),
      ref: ref,
    ),
  );
}

class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet({required this.initialDate, required this.ref});
  final DateTime initialDate;
  final WidgetRef ref;

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date;
  TimeOfDay _start = TimeOfDay.now();
  late TimeOfDay _end;
  String _category = 'Work';
  bool _saving = false;
  String _repeatType = 'none';
  int _repeatInterval = 1;
  String? _repeatDaysOfWeek;
  DateTime? _repeatEndsOn;
  int? _repeatEndsAfter;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    final now = TimeOfDay.now();
    _end = TimeOfDay(
        hour: (now.hour + 1) % 24, minute: now.minute);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.ref.read(plannerRepositoryProvider).addActivity(
          title: _titleCtrl.text.trim(),
          date: _date,
          startTime: timeStr(_start),
          endTime: timeStr(_end),
          category: _category,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          repeatType: _repeatType,
          repeatInterval: _repeatInterval,
          repeatDaysOfWeek: _repeatDaysOfWeek,
          repeatEndsOn: _repeatEndsOn,
          repeatEndsAfter: _repeatEndsAfter,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Activity',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDec('Title', Icons.title_rounded),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimePicker(
                  label: 'Start',
                  value: _start,
                  onChanged: (t) => setState(() => _start = t),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePicker(
                  label: 'End',
                  value: _end,
                  onChanged: (t) => setState(() => _end = t),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _selectRepeat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  const Text('Repeat', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const Spacer(),
                  Text(
                    _repeatLabel(_repeatType),
                    style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDec('Category', Icons.label_rounded),
            items: kCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDec('Description (optional)', Icons.notes_rounded),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(String type) => switch (type) {
        'daily' => 'Daily',
        'weekdays' => 'Weekdays',
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        'custom' => 'Custom',
        _ => 'Never',
      };

  void _selectRepeat() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Repeat pattern',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['none', 'daily', 'weekdays', 'weekly', 'monthly', 'custom'].map((type) {
              return ListTile(
                title: Text(_repeatLabel(type), style: const TextStyle(color: AppColors.textPrimary)),
                trailing: _repeatType == type ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, type),
              );
            }),
          ],
        ),
      ),
    );

    if (selected != null) {
      if (selected == 'custom') {
        _showCustomRepeatSheet();
      } else {
        setState(() {
          _repeatType = selected;
        });
      }
    }
  }

  void _showCustomRepeatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return CustomRepeatSheet(
          initialInterval: _repeatInterval,
          initialDaysOfWeek: _repeatDaysOfWeek,
          initialEndsOn: _repeatEndsOn,
          initialEndsAfter: _repeatEndsAfter,
          onSave: (interval, days, endsOn, endsAfter) {
            setState(() {
              _repeatType = 'custom';
              _repeatInterval = interval;
              _repeatDaysOfWeek = days;
              _repeatEndsOn = endsOn;
              _repeatEndsAfter = endsAfter;
            });
          },
        );
      },
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class _TimePicker extends StatelessWidget {
  const _TimePicker(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: value,
          builder: (ctx, child) => Theme(
            data: ThemeData.dark(),
            child: child!,
          ),
        );
        if (t != null) onChanged(t);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                Text(value.format(context),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomRepeatSheet extends StatefulWidget {
  const CustomRepeatSheet({
    super.key,
    required this.initialInterval,
    required this.initialDaysOfWeek,
    required this.initialEndsOn,
    required this.initialEndsAfter,
    required this.onSave,
  });

  final int initialInterval;
  final String? initialDaysOfWeek;
  final DateTime? initialEndsOn;
  final int? initialEndsAfter;
  final void Function(int interval, String? days, DateTime? endsOn, int? endsAfter) onSave;

  @override
  State<CustomRepeatSheet> createState() => _CustomRepeatSheetState();
}

class _CustomRepeatSheetState extends State<CustomRepeatSheet> {
  late int _interval;
  List<int> _selectedDays = [];
  String _endsType = 'never'; // 'never', 'date', 'after'
  DateTime? _endsOn;
  int _endsAfter = 10;
  final _intervalCtrl = TextEditingController();
  final _afterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _interval = widget.initialInterval;
    _intervalCtrl.text = _interval.toString();
    if (widget.initialDaysOfWeek != null && widget.initialDaysOfWeek!.isNotEmpty) {
      _selectedDays = widget.initialDaysOfWeek!.split(',').map(int.parse).toList();
    }
    _endsOn = widget.initialEndsOn;
    if (widget.initialEndsAfter != null) {
      _endsAfter = widget.initialEndsAfter!;
      _endsType = 'after';
    } else if (widget.initialEndsOn != null) {
      _endsType = 'date';
    }
    _afterCtrl.text = _endsAfter.toString();
  }

  @override
  void dispose() {
    _intervalCtrl.dispose();
    _afterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Custom Repeat',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Repeat every', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _intervalCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      _interval = parsed;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Text('weeks', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Repeat on', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final isSelected = _selectedDays.contains(dayNum);
              final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
              return ChoiceChip(
                label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedDays.add(dayNum);
                    } else {
                      _selectedDays.remove(dayNum);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text('Ends', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          RadioListTile<String>(
            title: const Text('Never', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            value: 'never',
            groupValue: _endsType,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _endsType = val!),
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                const Text('On ', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                TextButton(
                  onPressed: _endsType != 'date' ? null : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endsOn ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    if (picked != null) {
                      setState(() {
                        _endsOn = picked;
                      });
                    }
                  },
                  child: Text(_endsOn == null ? 'Select Date' : '${_endsOn!.day}/${_endsOn!.month}/${_endsOn!.year}'),
                ),
              ],
            ),
            value: 'date',
            groupValue: _endsType,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _endsType = val!;
                _endsOn ??= DateTime.now().add(const Duration(days: 30));
              });
            },
          ),
          RadioListTile<String>(
            title: Row(
              children: [
                const Text('After ', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _afterCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: _endsType == 'after',
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        _endsAfter = parsed;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text('occurrences', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              ],
            ),
            value: 'after',
            groupValue: _endsType,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _endsType = val!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final days = _selectedDays.isEmpty ? null : _selectedDays.join(',');
                final endsOn = _endsType == 'date' ? _endsOn : null;
                final endsAfter = _endsType == 'after' ? _endsAfter : null;
                widget.onSave(_interval, days, endsOn, endsAfter);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
