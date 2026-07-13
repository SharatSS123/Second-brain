import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/planner_providers.dart';
import '../utils/planner_utils.dart';
import 'tabs/today_tab.dart' show CustomRepeatSheet;

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.activity});
  final PlannerActivity activity;

  void _triggerDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(plannerRepositoryProvider);
    final isRecurring = activity.repeatType != 'none' || activity.recurrenceParentId != null;

    String scope = 'only';
    if (isRecurring) {
      final selectedScope = await showEditScopeBottomSheet(context, isDelete: true);
      if (selectedScope == null) return;
      scope = selectedScope;
    }

    if (isRecurring) {
      final parentId = activity.recurrenceParentId ?? activity.id;
      if (scope == 'entire') {
        await repo.deleteEntireSeries(parentId);
      } else if (scope == 'future') {
        await repo.deleteThisAndFuture(parentId, activity.date);
      } else {
        await repo.deleteOccurrenceOnly(parentId, activity.date);
      }
    } else {
      await repo.deleteActivity(activity.id);
    }

    if (context.mounted) Navigator.pop(context);
  }

  void _triggerEdit(BuildContext context, WidgetRef ref) async {
    final isRecurring = activity.repeatType != 'none' || activity.recurrenceParentId != null;

    String scope = 'only';
    if (isRecurring) {
      final selectedScope = await showEditScopeBottomSheet(context, isDelete: false);
      if (selectedScope == null) return;
      scope = selectedScope;
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditActivitySheet(
          activity: activity,
          scope: scope,
        ),
      );
    }
  }

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
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
            onPressed: () => _triggerEdit(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            onPressed: () => _triggerDelete(context, ref),
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
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        'custom' => 'Custom',
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

Future<String?> showEditScopeBottomSheet(BuildContext context, {required bool isDelete}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
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
            Text(
              isDelete ? 'Delete recurring activity' : 'Edit recurring activity',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the scope of this change:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.today_rounded, color: AppColors.primary),
              title: const Text('This activity only', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'only'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.card,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.next_plan_rounded, color: AppColors.primary),
              title: const Text('This and future activities', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'future'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.card,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.event_note_rounded, color: AppColors.primary),
              title: const Text('Entire series', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'entire'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: AppColors.card,
            ),
          ],
        ),
      );
    },
  );
}

class EditActivitySheet extends ConsumerStatefulWidget {
  const EditActivitySheet({
    super.key,
    required this.activity,
    required this.scope,
  });
  final PlannerActivity activity;
  final String scope;

  @override
  ConsumerState<EditActivitySheet> createState() => EditActivitySheetState();
}

class EditActivitySheetState extends ConsumerState<EditActivitySheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _category;
  bool _saving = false;
  late String _repeatType;
  late int _repeatInterval;
  String? _repeatDaysOfWeek;
  DateTime? _repeatEndsOn;
  int? _repeatEndsAfter;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.activity.title;
    _descCtrl.text = widget.activity.description ?? '';
    _date = widget.activity.date;
    _start = parseTimeOfDay(widget.activity.startTime);
    _end = parseTimeOfDay(widget.activity.endTime);
    _category = widget.activity.category;
    _repeatType = widget.activity.repeatType;
    _repeatInterval = widget.activity.repeatInterval;
    _repeatDaysOfWeek = widget.activity.repeatDaysOfWeek;
    _repeatEndsOn = widget.activity.repeatEndsOn;
    _repeatEndsAfter = widget.activity.repeatEndsAfter;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  TimeOfDay parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    
    try {
      String currentScope = widget.scope;
      if (_repeatType == 'none' && widget.activity.repeatType != 'none') {
        final stopScope = await showEditScopeBottomSheet(context, isDelete: false);
        if (stopScope == null) {
          setState(() => _saving = false);
          return;
        }
        currentScope = stopScope;
      }

      await ref.read(plannerRepositoryProvider).editActivityWithScope(
            id: widget.activity.id,
            scope: currentScope,
            date: _date,
            title: _titleCtrl.text.trim(),
            startTime: timeStr(_start),
            endTime: timeStr(_end),
            category: _category,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            repeatType: _repeatType,
            repeatInterval: _repeatInterval,
            repeatDaysOfWeek: _repeatDaysOfWeek,
            repeatEndsOn: _repeatEndsOn,
            repeatEndsAfter: _repeatEndsAfter,
          );
      if (mounted) {
        final nav = Navigator.of(context);
        nav.pop();
        if (nav.canPop()) {
          nav.pop();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving activity: $e\n$stackTrace');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          const Text('Edit Activity',
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
                child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _start,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      ),
                    );
                    if (t != null) setState(() => _start = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text(_start.format(context), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _end,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      ),
                    );
                    if (t != null) setState(() => _end = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text(_end.format(context), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
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
