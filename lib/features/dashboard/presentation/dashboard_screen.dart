import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';
import '../../tasks/providers/tasks_providers.dart';
import '../../notes/providers/notes_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    final tasksAsync = ref.watch(allTasksProvider);
    final notesAsync = ref.watch(allNotesProvider);
    final allTasks = (tasksAsync.value ?? []).cast<TasksTableData>();
    final allNotes = (notesAsync.value ?? []).cast<NotesTableData>();
    final today = DateTime(now.year, now.month, now.day);
    final todayTasks = allTasks.where((task) {
      final due = task.dueDate;
      if (due == null) return false;
      final dueDate = DateTime(due.year, due.month, due.day);
      return dueDate == today && !task.isCompleted;
    }).toList();
    final recentNotes = allNotes.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Brain'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Greeting
          Text(greeting, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(DateFormat('EEEE, MMMM d').format(now), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          // Quick stats row
          _StatsRow(
            tasksDue: allTasks.where((task) => !task.isCompleted).length,
            notes: allNotes.length,
            saved: allTasks.length + allNotes.length,
          ),
          const SizedBox(height: 24),

          // Today's tasks
          _SectionHeader(title: "Today's Tasks", onSeeAll: () {}),
          const SizedBox(height: 8),
          _TodayTasksCard(tasks: todayTasks),
          const SizedBox(height: 24),

          // Continue learning
          _SectionHeader(title: 'Continue Learning', onSeeAll: () {}),
          const SizedBox(height: 8),
          _LearningCard(),
          const SizedBox(height: 24),

          // Recent notes
          _SectionHeader(title: 'Recent Notes', onSeeAll: () {}),
          const SizedBox(height: 8),
          _RecentNotesCard(notes: recentNotes),
          const SizedBox(height: 24),

          // Watchlist
          _SectionHeader(title: 'Up Next to Watch', onSeeAll: () {}),
          const SizedBox(height: 8),
          _WatchlistCard(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int tasksDue;
  final int notes;
  final int saved;

  const _StatsRow({required this.tasksDue, required this.notes, required this.saved});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Tasks due', value: tasksDue.toString(), icon: Icons.check_circle_outline, color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Notes', value: notes.toString(), icon: Icons.note_alt_outlined, color: Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Saved', value: saved.toString(), icon: Icons.folder_outlined, color: Colors.green)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TodayTasksCard extends StatelessWidget {
  final List<TasksTableData> tasks;
  const _TodayTasksCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _EmptyState(icon: Icons.check_circle_outline, message: 'No tasks for today'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: tasks
              .take(3)
              .map(
                (task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(task.title),
                  subtitle: task.dueDate != null ? Text('Due ${DateFormat.yMMMd().format(task.dueDate!)}') : null,
                  trailing: Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _EmptyState(icon: Icons.school_outlined, message: 'No active learning topics'),
      ),
    );
  }
}

class _RecentNotesCard extends StatelessWidget {
  final List<NotesTableData> notes;
  const _RecentNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _EmptyState(icon: Icons.note_alt_outlined, message: 'No notes yet'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: notes
              .map(
                (note) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(note.title.isEmpty ? 'Untitled note' : note.title),
                  subtitle: Text(
                    note.content.isEmpty ? 'No content yet' : note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _EmptyState(icon: Icons.movie_outlined, message: 'Your watchlist is empty'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
