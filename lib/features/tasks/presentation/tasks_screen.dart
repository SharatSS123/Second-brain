import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tasks_providers.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingTasksProvider);
    final repo = ref.read(tasksRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 84, color: Colors.grey.shade400),
                    const SizedBox(height: 24),
                    Text(
                      'All caught up!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tap 'Add Task' to start organizing your day.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final task = tasks[i];
              return Dismissible(
                key: ValueKey(task.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => repo.delete(task.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.04),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (v) => repo.toggleComplete(task.id, v ?? false),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                            ),
                            if (task.description != null && task.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                task.description!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                              ),
                            ],
                            if (task.dueDate != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _formatDueDate(task.dueDate!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _dueDateTextColor(task.dueDate!, context),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.delete(task.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTaskSheetWidget(),
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = dueDateOnly.difference(todayDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return 'Overdue';
    return DateFormat('MMM dd, yyyy').format(dueDate);
  }

  Color _dueDateTextColor(DateTime dueDate, BuildContext context) {
    final today = DateTime.now();
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (dueDateOnly.isBefore(DateTime(today.year, today.month, today.day))) {
      return Colors.red.shade400;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

class _AddTaskSheetWidget extends ConsumerStatefulWidget {
  const _AddTaskSheetWidget();

  @override
  ConsumerState<_AddTaskSheetWidget> createState() => _AddTaskSheetWidgetState();
}

class _AddTaskSheetWidgetState extends ConsumerState<_AddTaskSheetWidget> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'Medium';
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Task', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Task title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: ['Low', 'Medium', 'High']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dueDate == null ? 'Due date' : '${_dueDate!.month}/${_dueDate!.day}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _titleController.text.isEmpty || _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Task'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(tasksRepositoryProvider).add(
            title: _titleController.text.trim(),
            description: _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
            priority: _priority,
            dueDate: _dueDate,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    }
    setState(() => _isSaving = false);
  }
}
