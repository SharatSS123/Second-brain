import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';
import '../../planner/presentation/tabs/today_tab.dart' show showAddActivitySheet;
import 'calendar_picker_screen.dart';
import 'profile_screen.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final activitiesAsync = ref.watch(todayActivitiesProvider);
    final todosAsync = ref.watch(todayTodosProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _DayHeader(selectedDate: selectedDate),
                Expanded(
                  child: activitiesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error loading')),
                    data: (activities) => _DayContent(
                      activities: activities,
                      todos: todosAsync.value ?? [],
                      selectedDate: selectedDate,
                    ),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () =>
                    _showAddPicker(context, ref, selectedDate),
                backgroundColor: AppColors.primary,
                elevation: 4,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPicker(
      BuildContext context, WidgetRef ref, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPickerSheet(
        onActivity: () {
          Navigator.pop(context);
          showAddActivitySheet(context, ref);
        },
        onTodo: () {
          Navigator.pop(context);
          _showAddTodoSheet(context, ref, selectedDate);
        },
      ),
    );
  }

  void _showAddTodoSheet(
      BuildContext context, WidgetRef ref, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTodoSheet(
        onAdd: (title) =>
            ref.read(plannerRepositoryProvider).addTodo(
                  title: title,
                  date: date,
                ),
      ),
    );
  }
}

// ── Add Picker Sheet ───────────────────────────────────────────────────────────

class _AddPickerSheet extends StatelessWidget {
  const _AddPickerSheet({required this.onActivity, required this.onTodo});
  final VoidCallback onActivity;
  final VoidCallback onTodo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'What would you like to add?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.schedule_rounded,
                  label: 'Activity',
                  subtitle: 'Scheduled time block',
                  color: AppColors.primary,
                  onTap: onActivity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.check_box_outline_blank_rounded,
                  label: 'To Do',
                  subtitle: 'Quick task for today',
                  color: AppColors.green,
                  onTap: onTodo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Add Todo Sheet ─────────────────────────────────────────────────────────────

class _AddTodoSheet extends StatefulWidget {
  const _AddTodoSheet({required this.onAdd});
  final Future<void> Function(String title) onAdd;

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add To Do',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'What needs to be done?'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving || _ctrl.text.trim().isEmpty
                    ? null
                    : _save,
                child: const Text('Add Task',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await widget.onAdd(title);
    if (mounted) Navigator.pop(context);
  }
}

// ── Edit Todo Sheet ────────────────────────────────────────────────────────────

class _EditTodoSheet extends StatefulWidget {
  const _EditTodoSheet({required this.todo, required this.onSave, required this.onDelete});
  final DayTodo todo;
  final Future<void> Function(String title) onSave;
  final Future<void> Function() onDelete;

  @override
  State<_EditTodoSheet> createState() => _EditTodoSheetState();
}

class _EditTodoSheetState extends State<_EditTodoSheet> {
  late final _ctrl = TextEditingController(text: widget.todo.title);
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Edit To Do',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Task title'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            await widget.onDelete();
                            if (mounted) Navigator.pop(context);
                          },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _save,
                    child: const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(title);
    if (mounted) Navigator.pop(context);
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DayHeader extends ConsumerWidget {
  const _DayHeader({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayName = DateFormat('EEEE').format(selectedDate);
    final dateStr = DateFormat('MMM d, yyyy').format(selectedDate);
    final isToday = dateOnly(selectedDate) == dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: AppColors.textSecondary),
            onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => ref
                          .read(selectedDateProvider.notifier)
                          .state = selectedDate
                          .subtract(const Duration(days: 1)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalendarPickerScreen()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                dayName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('TODAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      )),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => ref
                          .read(selectedDateProvider.notifier)
                          .state =
                          selectedDate.add(const Duration(days: 1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Text('S',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Content (activities + todos) ──────────────────────────────────────────

class _DayContent extends ConsumerWidget {
  const _DayContent({
    required this.activities,
    required this.todos,
    required this.selectedDate,
  });
  final List<PlannerActivity> activities;
  final List<DayTodo> todos;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = activities.where(
        (a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted);
    final currentActivity = active.isNotEmpty ? active.first : null;

    return CustomScrollView(
      slivers: [
        if (currentActivity != null)
          SliverToBoxAdapter(
              child: _NowCard(activity: currentActivity)),
        if (activities.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyActivities(selectedDate: selectedDate, ref: ref),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: const Text(
                'TIMELINE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _TimelineRow(
                activity: activities[i],
                isFirst: i == 0,
                isLast: i == activities.length - 1,
                ref: ref,
              ),
              childCount: activities.length,
            ),
          ),
        ],

        // ── TO DO section ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _TodoSection(
            todos: todos,
            selectedDate: selectedDate,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── To Do Section ─────────────────────────────────────────────────────────────

class _TodoSection extends ConsumerStatefulWidget {
  const _TodoSection({required this.todos, required this.selectedDate});
  final List<DayTodo> todos;
  final DateTime selectedDate;

  @override
  ConsumerState<_TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends ConsumerState<_TodoSection> {
  void _openEdit(DayTodo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTodoSheet(
        todo: todo,
        onSave: (title) =>
            ref.read(plannerRepositoryProvider).updateTodoTitle(todo.id, title),
        onDelete: () =>
            ref.read(plannerRepositoryProvider).deleteTodo(todo.id),
      ),
    );
  }

  void _showAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTodoSheet(
        onAdd: (title) => ref.read(plannerRepositoryProvider).addTodo(
              title: title,
              date: widget.selectedDate,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.todos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 0, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                todos.isEmpty
                    ? 'TO DO'
                    : 'TO DO (${todos.length})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...todos.map((todo) => _TodoRow(
                todo: todo,
                onToggle: () => ref
                    .read(plannerRepositoryProvider)
                    .toggleTodo(todo.id, todo.isCompleted),
                onTap: () => _openEdit(todo),
              )),
          TextButton.icon(
            onPressed: _showAdd,
            icon: const Icon(Icons.add_rounded, size: 16,
                color: AppColors.textSecondary),
            label: const Text('Add Task',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.onToggle,
    required this.onTap,
  });
  final DayTodo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: todo.isCompleted
                      ? AppColors.green.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: todo.isCompleted
                        ? AppColors.green
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.green, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  color: todo.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontSize: 14,
                  decoration: todo.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Now Card ───────────────────────────────────────────────────────────────────

class _NowCard extends ConsumerWidget {
  const _NowCard({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtasksAsync = ref.watch(activitySubtasksProvider(activity.id));
    final mLeft = minutesLeft(activity.endTime);
    final s = parseTod(activity.startTime);
    final e = parseTod(activity.endTime);
    final total = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    final elapsed = total - mLeft;
    final timeProgress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    return subtasksAsync.when(
      loading: () => _buildCard(timeProgress, null, null, mLeft),
      error: (_, __) => _buildCard(timeProgress, null, null, mLeft),
      data: (subtasks) {
        if (subtasks.isEmpty) {
          return _buildCard(timeProgress, null, null, mLeft);
        }
        final done = subtasks.where((s) => s.isCompleted).length;
        return _buildCard(done / subtasks.length, done, subtasks.length, mLeft);
      },
    );
  }

  Widget _buildCard(double progress, int? done, int? total, int mLeft) {
    final (_, icon) = categoryStyle(activity.category);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1D8A), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge('NOW'),
              const Spacer(),
              if (done != null && total != null)
                Text('$done of $total done',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13))
              else
                Text(mLeft > 0 ? '$mLeft min left' : 'Ending',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text(
                        '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [_badge('In Progress', green: true)]),
          const SizedBox(height: 8),
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

  Widget _badge(String text, {bool green = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: green
            ? Colors.greenAccent.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (green)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(
                  color: Colors.greenAccent, shape: BoxShape.circle),
            ),
          Text(text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

// ── Timeline Row ───────────────────────────────────────────────────────────────

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    required this.ref,
  });
  final PlannerActivity activity;
  final bool isFirst, isLast;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    final isNow = isActiveNow(activity.startTime, activity.endTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  displayTime(activity.startTime),
                  style: TextStyle(
                    color: isNow ? AppColors.primary : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight:
                        isNow ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 1.5, height: 10, color: AppColors.divider),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 17),
                  decoration: BoxDecoration(
                    color: isNow ? AppColors.primary : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                      child: Container(
                          width: 1.5, color: AppColors.divider)),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _openDetail(context),
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.primary.withValues(alpha: 0.07)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: isNow
                        ? Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.25),
                            width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
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
                          children: [
                            Text(activity.title,
                                style: TextStyle(
                                  color: activity.isCompleted
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: activity.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                )),
                            if (activity.endTime.isNotEmpty)
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
                          width: 22,
                          height: 22,
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
                                  color: Colors.white, size: 13)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActivityQuickSheet(activity: activity),
    );
  }
}

// ── Activity Quick Sheet ───────────────────────────────────────────────────────

class _ActivityQuickSheet extends ConsumerStatefulWidget {
  const _ActivityQuickSheet({required this.activity});
  final PlannerActivity activity;

  @override
  ConsumerState<_ActivityQuickSheet> createState() =>
      _ActivityQuickSheetState();
}

class _ActivityQuickSheetState
    extends ConsumerState<_ActivityQuickSheet> {
  final _addTaskController = TextEditingController();
  bool _showAddField = false;

  @override
  void dispose() {
    _addTaskController.dispose();
    super.dispose();
  }

  Future<void> _addSubtask(List<ActivitySubtask> existing) async {
    final title = _addTaskController.text.trim();
    if (title.isEmpty) return;
    await ref.read(plannerRepositoryProvider).addSubtask(
          activityId: widget.activity.id,
          title: title,
          sortOrder: existing.length,
        );
    _addTaskController.clear();
    setState(() => _showAddField = false);
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final (color, icon) = categoryStyle(activity.category);
    final subtasksAsync = ref.watch(activitySubtasksProvider(activity.id));

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            subtasksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (subtasks) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtasks.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('TASKS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            )),
                        const Spacer(),
                        Text(
                          '${subtasks.where((s) => s.isCompleted).length}/${subtasks.length}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: subtasks.isNotEmpty
                            ? subtasks
                                    .where((s) => s.isCompleted)
                                    .length /
                                subtasks.length
                            : 0,
                        minHeight: 3,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: subtasks.length,
                        itemBuilder: (ctx, i) {
                          final sub = subtasks[i];
                          return Dismissible(
                            key: ValueKey(sub.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.only(right: 12),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.red, size: 18),
                            ),
                            onDismissed: (_) => ref
                                .read(plannerRepositoryProvider)
                                .deleteSubtask(sub.id),
                            child: InkWell(
                              onTap: () => ref
                                  .read(plannerRepositoryProvider)
                                  .toggleSubtask(
                                      sub.id, sub.isCompleted),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 7, horizontal: 2),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: sub.isCompleted
                                            ? AppColors.green
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: sub.isCompleted
                                              ? AppColors.green
                                              : AppColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: sub.isCompleted
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 12)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        sub.title,
                                        style: TextStyle(
                                          color: sub.isCompleted
                                              ? AppColors.textMuted
                                              : AppColors.textPrimary,
                                          fontSize: 14,
                                          decoration: sub.isCompleted
                                              ? TextDecoration
                                                  .lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_showAddField)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addTaskController,
                              autofocus: true,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Task name',
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 8),
                                border: UnderlineInputBorder(),
                              ),
                              onSubmitted: (_) =>
                                  _addSubtask(subtasks),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _addSubtask(subtasks),
                            child: const Icon(Icons.send_rounded,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() {
                              _showAddField = false;
                              _addTaskController.clear();
                            }),
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 20),
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAddField = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add task'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(plannerRepositoryProvider)
                          .deleteActivity(activity.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(plannerRepositoryProvider)
                          .toggleComplete(
                              activity.id, activity.isCompleted);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: Icon(
                      activity.isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                        activity.isCompleted ? 'Undo' : 'Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activity.isCompleted
                          ? AppColors.border
                          : AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Activities ───────────────────────────────────────────────────────────

class _EmptyActivities extends ConsumerWidget {
  const _EmptyActivities({required this.selectedDate, required this.ref});
  final DateTime selectedDate;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: AppColors.primary.withValues(alpha: 0.6),
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text('No activities planned',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          const Text(
            'Plan your day or apply a template.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.push('/templates'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply Template',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
