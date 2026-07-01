import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/tasks_providers.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading:
            IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () {}),
        title: const Text('Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AllTasksTab(),
          _TodayTab(),
          _UpcomingTab(),
          _CompletedTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddTaskSheet(),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _AllTasksTab extends ConsumerWidget {
  const _AllTasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingTasksProvider);
    final allAsync = ref.watch(allTasksProvider);
    final all = allAsync.value ?? [];
    final completed = all.where((t) => t.isCompleted).length;
    final total = all.length;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) => Column(
        children: [
          if (total > 0) _WeekProgressCard(completed: completed, total: total),
          Expanded(
            child: tasks.isEmpty
                ? const _EmptyTasks(
                    message: 'All caught up!',
                    subtitle: "Tap + to add a task",
                  )
                : _GroupedTaskList(tasks: tasks, ref: ref),
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  const _TodayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(todayTasksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) => tasks.isEmpty
          ? const _EmptyTasks(
              message: "Nothing due today",
              subtitle: "Enjoy your free time!",
            )
          : _GroupedTaskList(tasks: tasks, ref: ref),
    );
  }
}

class _UpcomingTab extends ConsumerWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(upcomingTasksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) => tasks.isEmpty
          ? const _EmptyTasks(
              message: "No upcoming tasks",
              subtitle: "Your future is clear",
            )
          : _GroupedTaskList(tasks: tasks, ref: ref),
    );
  }
}

class _CompletedTab extends ConsumerWidget {
  const _CompletedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(completedTasksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) => tasks.isEmpty
          ? const _EmptyTasks(
              message: "No completed tasks",
              subtitle: "Complete tasks to see them here",
            )
          : _GroupedTaskList(tasks: tasks, ref: ref, showCompleted: true),
    );
  }
}

// ── Weekly Progress Card ──────────────────────────────────────────────────────

class _WeekProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const _WeekProgressCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : completed / total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Week Progress',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed / $total tasks completed',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 5,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Grouped Task List ─────────────────────────────────────────────────────────

class _GroupedTaskList extends StatelessWidget {
  final List<TasksTableData> tasks;
  final WidgetRef ref;
  final bool showCompleted;

  const _GroupedTaskList(
      {required this.tasks, required this.ref, this.showCompleted = false});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(tasks);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final entry = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(label: entry.key, count: entry.value.length),
            ...entry.value.map(
              (t) => _TaskCard(
                task: t,
                onToggle: () => ref
                    .read(tasksRepositoryProvider)
                    .toggleComplete(t.id, !t.isCompleted),
                onDelete: () =>
                    ref.read(tasksRepositoryProvider).delete(t.id),
              ),
            ),
          ],
        );
      },
    );
  }

  List<MapEntry<String, List<TasksTableData>>> _groupByDate(
      List<TasksTableData> tasks) {
    final map = <String, List<TasksTableData>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final task in tasks) {
      String key;
      if (task.dueDate == null) {
        key = 'No date';
      } else {
        final d = task.dueDate!;
        final date = DateTime(d.year, d.month, d.day);
        if (date == today) {
          key = 'Today · ${DateFormat('EEE, MMM d').format(d)}';
        } else if (date == tomorrow) {
          key = 'Tomorrow · ${DateFormat('EEE, MMM d').format(d)}';
        } else {
          key = DateFormat('EEE, MMM d').format(d);
        }
      }
      map.putIfAbsent(key, () => []).add(task);
    }
    return map.entries.toList();
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  final int count;
  const _DateHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TasksTableData task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard(
      {required this.task, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tags = task.tags?.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ?? [];

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                margin: const EdgeInsets.only(top: 1),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppColors.primary
                        : AppColors.textMuted,
                    width: 1.5,
                  ),
                  color: task.isCompleted
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 14, color: AppColors.primary)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: tags
                          .take(2)
                          .map((tag) => _TagChip(tag: tag))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            if (task.dueDate != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('h:mm a').format(task.dueDate!),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  if (task.isRecurring)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.repeat_rounded,
                          size: 13, color: AppColors.textMuted),
                    ),
                ],
              ),
            ],
            if (task.priority == 'High')
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.tagColor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final String message;
  final String subtitle;
  const _EmptyTasks({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Add Task Sheet ────────────────────────────────────────────────────────────

class _AddTaskSheet extends ConsumerStatefulWidget {
  const _AddTaskSheet();

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Medium';
  String? _category;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isSaving = false;

  static const _categories = ['Work', 'Personal', 'Health', 'Learning', 'Finance'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 16),
            const Text(
              'New Task',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Task title *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _category,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(
                      _dueDate == null
                          ? 'Due date'
                          : DateFormat('MMM d').format(_dueDate!),
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(
                      _dueTime == null ? 'Time' : _dueTime!.format(context),
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Task',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      DateTime? due;
      if (_dueDate != null) {
        final t = _dueTime ?? TimeOfDay.now();
        due = DateTime(
            _dueDate!.year, _dueDate!.month, _dueDate!.day, t.hour, t.minute);
      }
      await ref.read(tasksRepositoryProvider).add(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            priority: _priority,
            dueDate: due,
            tags: _category != null ? [_category!] : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
