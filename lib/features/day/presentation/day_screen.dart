import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../checklists/providers/checklists_providers.dart';
import 'activity_focus_screen.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';
import '../../planner/presentation/tabs/today_tab.dart' show showAddActivitySheet;
import '../../planner/presentation/activity_detail_screen.dart' show EditActivitySheet, showEditScopeBottomSheet;
import 'calendar_picker_screen.dart';
import 'profile_screen.dart';

class DayScreen extends ConsumerWidget {
  final bool expandTodo;
  const DayScreen({super.key, this.expandTodo = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final activitiesAsync = ref.watch(todayActivitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
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
                  selectedDate: selectedDate,
                  expandTodo: expandTodo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      onAdd: (title, checklistId) =>
          ref.read(plannerRepositoryProvider).addTodo(
                title: title,
                date: date,
                checklistId: checklistId,
              ),
    ),
  );
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

class _AddTodoSheet extends ConsumerStatefulWidget {
  const _AddTodoSheet({required this.onAdd});
  final Future<void> Function(String title, String? checklistId) onAdd;

  @override
  ConsumerState<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends ConsumerState<_AddTodoSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String? _selectedChecklistId;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(checklistsProvider);
    final checklists = checklistsAsync.value ?? [];

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
            const SizedBox(height: 16),
            if (checklists.isNotEmpty) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppColors.surface,
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Link Checklist (Optional)',
                    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ...checklists.map((l) => DropdownMenuItem<String>(
                          value: l.id,
                          child: Text(l.name),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedChecklistId = val),
                ),
              ),
              const SizedBox(height: 20),
            ],
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

  Future<_AddTodoSheetState> _save() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return this;
    setState(() => _saving = true);
    try {
      await widget.onAdd(title, _selectedChecklistId);
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error adding todo: $e\n$stack');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add todo: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
    return this;
  }
}

// ── Edit Todo Sheet ────────────────────────────────────────────────────────────

class _EditTodoSheet extends ConsumerStatefulWidget {
  const _EditTodoSheet({required this.todo, required this.onSave, required this.onDelete});
  final DayTodo todo;
  final Future<void> Function(String title, String? checklistId) onSave;
  final Future<void> Function() onDelete;

  @override
  ConsumerState<_EditTodoSheet> createState() => _EditTodoSheetState();
}

class _EditTodoSheetState extends ConsumerState<_EditTodoSheet> {
  late final _ctrl = TextEditingController(text: widget.todo.title);
  bool _saving = false;
  String? _selectedChecklistId;

  @override
  void initState() {
    super.initState();
    _selectedChecklistId = widget.todo.checklistId;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(checklistsProvider);
    final checklists = checklistsAsync.value ?? [];

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
            const SizedBox(height: 16),
            if (checklists.isNotEmpty) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppColors.surface,
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedChecklistId,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Link Checklist (Optional)',
                    labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    ...checklists.map((l) => DropdownMenuItem<String>(
                          value: l.id,
                          child: Text(l.name),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedChecklistId = val),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            try {
                              await widget.onDelete();
                              if (mounted) Navigator.pop(context);
                            } catch (e, stack) {
                              debugPrint('Error deleting todo: $e\n$stack');
                              if (mounted) {
                                setState(() => _saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete todo: $e'),
                                    backgroundColor: AppColors.red,
                                  ),
                                );
                              }
                            }
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
    try {
      await widget.onSave(title, _selectedChecklistId);
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('Error saving todo: $e\n$stack');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save todo: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
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
            onTap: () => _showAddPicker(context, ref, selectedDate),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
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

class _DayContent extends ConsumerStatefulWidget {
  const _DayContent({
    super.key,
    required this.activities,
    required this.selectedDate,
    this.expandTodo = false,
  });
  final List<PlannerActivity> activities;
  final DateTime selectedDate;
  final bool expandTodo;

  @override
  ConsumerState<_DayContent> createState() => _DayContentState();
}

class _DayContentState extends ConsumerState<_DayContent> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _addCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late bool _todoExpanded;

  @override
  void initState() {
    super.initState();
    _todoExpanded = widget.expandTodo;
    _scrollToActiveActivity();
  }

  @override
  void didUpdateWidget(_DayContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.activities != widget.activities) {
      _scrollToActiveActivity();
    }
    if (oldWidget.expandTodo != widget.expandTodo) {
      _todoExpanded = widget.expandTodo;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _addCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTask() async {
    final title = _addCtrl.text.trim();
    if (title.isEmpty) return;
    _addCtrl.clear();
    try {
      await ref.read(plannerRepositoryProvider).addTodo(
            title: title,
            date: widget.selectedDate,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _openEdit(DayTodo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTodoSheet(
        todo: todo,
        onSave: (title, checklistId) =>
            ref.read(plannerRepositoryProvider).updateTodo(
                  id: todo.id,
                  title: title,
                  checklistId: checklistId,
                ),
        onDelete: () =>
            ref.read(plannerRepositoryProvider).deleteTodo(todo.id),
      ),
    );
  }

  void _scrollToActiveActivity() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final activeIndex = widget.activities.indexWhere(
          (a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted);

      if (activeIndex != -1) {
        final targetIndex = activeIndex > 0 ? activeIndex - 1 : activeIndex;

        double offset = 0.0;
        offset += 45.0; // timeline label offset
        offset += targetIndex * 66.0; // item offsets

        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = offset.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activities.where(
        (a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted);
    final currentActivity = active.isNotEmpty ? active.first : null;
    final todosAsync = ref.watch(todayTodosProvider);
    final todos = todosAsync.value ?? [];
    final openTodosCount = todos.where((t) => !t.isCompleted).length;

    return Column(
      children: [
        if (currentActivity != null)
          _NowCard(activity: currentActivity),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (widget.activities.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 20),
                    child: _EmptyActivities(selectedDate: widget.selectedDate, ref: ref),
                  ),
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
                      activity: widget.activities[i],
                      isFirst: i == 0,
                      isLast: i == widget.activities.length - 1,
                      ref: ref,
                    ),
                    childCount: widget.activities.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
        // ── TO DO Section Fixed at the Bottom ──
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            border: const Border(
              top: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TO DO',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _todoExpanded = !_todoExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '$openTodosCount ${openTodosCount == 1 ? "Open Task" : "Open Tasks"}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _todoExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_todoExpanded) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border, width: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _addCtrl,
                            focusNode: _focusNode,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add a new task...',
                              hintStyle: TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _addTask(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addTask,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                if (todos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No tasks for today',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: todos.length,
                        itemBuilder: (context, idx) {
                          final todo = todos[idx];
                          return _DismissibleTodoRow(
                            key: ValueKey(todo.id),
                            todo: todo,
                            index: idx,
                            onTap: () => _openEdit(todo),
                          );
                        },
                        onReorder: (oldIdx, newIdx) async {
                          if (newIdx > oldIdx) {
                            newIdx -= 1;
                          }
                          final updatedList = [...todos];
                          final moved = updatedList.removeAt(oldIdx);
                          updatedList.insert(newIdx, moved);
                          await ref.read(plannerRepositoryProvider).updateTodosOrder(updatedList);
                        },
                        buildDefaultDragHandles: false,
                      ),
                    ),
                  ),
              ] else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Draggable To Do Sheet ──────────────────────────────────────────────────────


String getRelativeDateStr(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final yesterday = today.subtract(const Duration(days: 1));
  
  final compareDate = DateTime(date.year, date.month, date.day);
  if (compareDate == today) {
    return 'Today';
  } else if (compareDate == tomorrow) {
    return 'Tomorrow';
  } else if (compareDate == yesterday) {
    return 'Yesterday';
  } else {
    return DateFormat('MMM d').format(date);
  }
}

class _DismissibleTodoRow extends ConsumerWidget {
  const _DismissibleTodoRow({
    super.key,
    required this.todo,
    required this.index,
    required this.onTap,
  });
  final DayTodo todo;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Dismissible(
      key: ValueKey(todo.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await ref.read(plannerRepositoryProvider).deleteTodo(todo.id);
          return true;
        } else if (direction == DismissDirection.startToEnd) {
          await ref.read(plannerRepositoryProvider).toggleTodo(todo.id, todo.isCompleted, targetDate: selectedDate);
          return false;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 20),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (val) {
                        ref.read(plannerRepositoryProvider).toggleTodo(todo.id, todo.isCompleted, targetDate: selectedDate);
                      },
                      activeColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.textMuted, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            color: todo.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          getRelativeDateStr(todo.date),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoRow extends ConsumerStatefulWidget {
  const _TodoRow({
    super.key,
    required this.todo,
    required this.selectedDate,
    required this.onToggle,
    required this.onTap,
  });
  final DayTodo todo;
  final DateTime selectedDate;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  ConsumerState<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends ConsumerState<_TodoRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChecklist = widget.todo.checklistId != null;
    final checklistItemsAsync = hasChecklist
        ? ref.watch(checklistItemsProvider(widget.todo.checklistId!))
        : const AsyncValue<List<ChecklistItem>>.data([]);

    // Calculate overdue status
    final todoDay = DateTime(widget.todo.date.year, widget.todo.date.month, widget.todo.date.day);
    final selectedDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    final daysOverdue = selectedDay.difference(todoDay).inDays;

    Color? overdueColor;
    String? overdueText;
    if (daysOverdue > 0 && !widget.todo.isCompleted) {
      if (daysOverdue < 3) {
        overdueColor = AppColors.amber;
        overdueText = '$daysOverdue ${daysOverdue == 1 ? "day" : "days"} due';
      } else {
        overdueColor = AppColors.red;
        overdueText = '$daysOverdue days due';
      }
    }

    final borderColor = overdueColor ?? AppColors.border;
    final borderThickness = overdueColor != null ? 1.0 : 0.5;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderThickness),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: hasChecklist
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : widget.onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.todo.isCompleted
                              ? AppColors.green.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: widget.todo.isCompleted
                                ? AppColors.green
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: widget.todo.isCompleted
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.green, size: 13)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.todo.title,
                                  style: TextStyle(
                                    color: widget.todo.isCompleted
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: widget.todo.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              if (overdueText != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: overdueColor!.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: overdueColor, width: 0.5),
                                  ),
                                  child: Text(
                                    overdueText.toUpperCase(),
                                    style: TextStyle(
                                      color: overdueColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (hasChecklist) ...[
                            const SizedBox(height: 2),
                            checklistItemsAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (items) {
                                if (items.isEmpty) {
                                  return const Text('Empty checklist',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11));
                                }
                                final checked =
                                    items.where((i) => i.isChecked).length;
                                return Text(
                                  '📋 $checked of ${items.length} completed',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasChecklist) ...[
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textMuted, size: 16),
                      onPressed: widget.onTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            if (hasChecklist && _isExpanded) ...[
              const Divider(height: 1, color: AppColors.divider),
              checklistItemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1.2))),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error: $e',
                      style: const TextStyle(
                          color: AppColors.red, fontSize: 11)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Text('Checklist is empty',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    );
                  }
                  return Container(
                    color: AppColors.bg.withValues(alpha: 0.1),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: item.isChecked,
                                  onChanged: (val) {
                                    ref
                                        .read(checklistsRepositoryProvider)
                                        .toggleItem(item.id, item.isChecked);
                                  },
                                  activeColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.textMuted, width: 1.2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(3)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: item.isChecked
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                    decoration: item.isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
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
    final mLeft = minutesLeft(activity.endTime);
    final s = parseTod(activity.startTime);
    final e = parseTod(activity.endTime);
    final total = (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    final elapsed = total - mLeft;
    final timeProgress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;

    final (_, icon) = categoryStyle(activity.category);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1D8A), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'NOW • ${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActivityFocusScreen(activity: activity),
                    ),
                  );
                },
                icon: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 12),
                label: const Text(
                  'Focus',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: timeProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          ),
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
                            _buildRecurrenceBadge(activity),
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

  Widget _buildRecurrenceBadge(PlannerActivity activity) {
    if (activity.repeatType == 'none') return const SizedBox.shrink();
    
    final interval = activity.repeatInterval;
    String label = '';
    switch (activity.repeatType) {
      case 'daily':
        label = interval > 1 ? 'Every $interval days' : 'Daily';
        break;
      case 'weekdays':
        label = 'Every weekday';
        break;
      case 'weekly':
        label = interval > 1 ? 'Every $interval weeks' : 'Weekly';
        break;
      case 'monthly':
        label = interval > 1 ? 'Every $interval months' : 'Monthly';
        break;
      case 'custom':
        if (activity.repeatDaysOfWeek != null && activity.repeatDaysOfWeek!.isNotEmpty) {
          final daysMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
          final days = activity.repeatDaysOfWeek!.split(',').map(int.parse).map((d) => daysMap[d] ?? '').join(', ');
          label = interval > 1 ? 'Every $interval weeks on $days' : 'Weekly on $days';
        } else {
          label = 'Custom recurrence';
        }
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded, color: AppColors.textMuted, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w400),
          ),
        ],
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

  void _triggerDelete(BuildContext context) async {
    final repo = ref.read(plannerRepositoryProvider);
    final activity = widget.activity;
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

  void _triggerEdit(BuildContext context) async {
    final activity = widget.activity;
    final isRecurring = activity.repeatType != 'none' || activity.recurrenceParentId != null;

    String scope = 'only';
    if (isRecurring) {
      final selectedScope = await showEditScopeBottomSheet(context, isDelete: false);
      if (selectedScope == null) return;
      scope = selectedScope;
    }

    if (context.mounted) {
      Navigator.pop(context);
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
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                  onPressed: () => _triggerEdit(context),
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
                    onPressed: () => _triggerDelete(context),
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
