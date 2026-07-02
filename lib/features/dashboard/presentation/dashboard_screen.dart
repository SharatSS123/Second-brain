import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../../tasks/providers/tasks_providers.dart';
import '../../notes/providers/notes_providers.dart';
import '../../learning/providers/learning_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final allTasksAsync = ref.watch(allTasksProvider);
    final todayTasksAsync = ref.watch(todayTasksProvider);
    final notesAsync = ref.watch(allNotesProvider);
    final topicsAsync = ref.watch(learningTopicsProvider);

    final allTasks = allTasksAsync.value ?? [];
    final todayTasks = todayTasksAsync.value ?? [];
    final notes = notesAsync.value ?? [];
    final topics = topicsAsync.value ?? [];

    final pending = allTasks.where((t) => !t.isCompleted).length;
    final completed = allTasks.where((t) => t.isCompleted).length;
    final total = allTasks.length;
    final progressPercent = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('CORTEX'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
          Stack(
            children: [
              IconButton(
                  icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
              if (todayTasks.isNotEmpty)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),
          // Greeting
          Text(
            '${_greeting(now.hour)}, Sharat 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, MMMM d').format(now),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Daily Progress Card
          _ProgressCard(progress: progressPercent, completed: completed, total: total),
          const SizedBox(height: 20),

          // Today at a glance
          Text(
            'Today at a glance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          _GlanceRow(
            tasksDue: pending,
            saved: notes.length,
            onLearnTap: () => context.go('/learning'),
          ),
          const SizedBox(height: 24),

          // Today's Tasks
          _SectionHeader(
            title: "Today's Tasks",
            onSeeAll: () => context.go('/tasks'),
          ),
          const SizedBox(height: 8),
          if (todayTasks.isEmpty)
            _EmptyCard(
              icon: Icons.check_circle_outline,
              message: 'No tasks due today',
            )
          else
            ...todayTasks.take(3).map((t) => _TaskRow(task: t, ref: ref)),
          const SizedBox(height: 24),

          // Continue Learning
          if (topics.isNotEmpty) ...[
            _SectionHeader(
              title: 'Continue Learning',
              onSeeAll: () => context.go('/learning'),
            ),
            const SizedBox(height: 8),
            _LearningCard(topic: topics.first),
            const SizedBox(height: 24),
          ],

          // Recent Notes
          _SectionHeader(
            title: 'Recent Notes',
            onSeeAll: () => context.go('/notes'),
          ),
          const SizedBox(height: 8),
          if (notes.isEmpty)
            _EmptyCard(icon: Icons.note_alt_outlined, message: 'No notes yet')
          else
            ...notes.take(2).map((n) => _NoteRow(note: n)),
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

// ── Progress Card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _ProgressCard(
      {required this.progress, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final message = percent == 0
        ? "Let's get started!"
        : percent < 50
            ? 'Keep it up!'
            : percent < 100
                ? 'Great start! Keep going.'
                : 'All done today! 🎉';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$completed / ${total == 0 ? 0 : total} tasks',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: _CircleProgressPainter(progress: progress),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}

// ── Glance Row ────────────────────────────────────────────────────────────────

class _GlanceRow extends StatelessWidget {
  final int tasksDue;
  final int saved;
  final VoidCallback onLearnTap;

  const _GlanceRow(
      {required this.tasksDue, required this.saved, required this.onLearnTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GlanceBox(
            label: 'Tasks due',
            value: tasksDue.toString(),
            color: AppColors.blue,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GlanceBox(
            label: 'Event',
            icon: Icons.calendar_today_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: onLearnTap,
            borderRadius: BorderRadius.circular(12),
            child: _GlanceBox(
              label: 'Continue',
              icon: Icons.school_rounded,
              color: AppColors.amber,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GlanceBox(
            label: 'Saved',
            value: saved.toString(),
            color: AppColors.green,
            icon: Icons.bookmark_outline,
          ),
        ),
      ],
    );
  }
}

class _GlanceBox extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color color;

  const _GlanceBox(
      {required this.label, this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Task Row ──────────────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final TasksTableData task;
  final WidgetRef ref;

  const _TaskRow({required this.task, required this.ref});

  @override
  Widget build(BuildContext context) {
    final firstTag = task.tags?.split(',').firstOrNull?.trim();
    final tagColor = firstTag != null ? AppColors.tagColor(firstTag) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref
                .read(tasksRepositoryProvider)
                .toggleComplete(task.id, !task.isCompleted),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppColors.primary : AppColors.textMuted,
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
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (firstTag != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      firstTag,
                      style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (task.dueDate != null)
            Text(
              DateFormat('h:mm a').format(task.dueDate!),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

// ── Learning Card ─────────────────────────────────────────────────────────────

class _LearningCard extends StatelessWidget {
  final LearningTopicsTableData topic;
  const _LearningCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(topic.color) ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: topic.progressPercent / 100,
                    backgroundColor: AppColors.border,
                    color: color,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${topic.progressPercent}% complete',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }
}

// ── Note Row ──────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  final NotesTableData note;
  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note.content,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('MMM d').format(note.updatedAt),
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          if (note.isPinned) ...[
            const SizedBox(width: 6),
            const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.amber),
          ],
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all',
            style: TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Text(message,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
