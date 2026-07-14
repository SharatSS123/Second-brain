import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';
import '../../day/presentation/profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final activities = ref.watch(homeTodayActivitiesProvider).value ?? [];
    final todos = ref.watch(homeTodayTodosProvider).value ?? [];

    final totalActivities = activities.length;
    final completedActivities = activities.where((a) => a.isCompleted).length;
    final totalTodos = todos.length;
    final completedTodos = todos.where((t) => t.isCompleted).length;

    final nowActivity = activities
        .where((a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted)
        .firstOrNull;

    final nowMins = now.hour * 60 + now.minute;
    final upcoming = activities
        .where((a) {
          if (a.isCompleted) return false;
          final s = parseTod(a.startTime);
          return s.hour * 60 + s.minute > nowMins;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final upNext = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: false,
              backgroundColor: AppColors.bg,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AppColors.textSecondary),
                onPressed: () =>
                    mainScaffoldKey.currentState?.openDrawer(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('CORTEX',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textSecondary),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Notifications coming soon'),
                        behavior: SnackBarBehavior.floating),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      child: const Text('S',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                ),
              ],
            ),

            // ── Content ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Greeting
                  Text(
                    '${_greeting(now.hour)}, Sharat! 👋',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // ── Progress Card ────────────────────────────────────────
                  _ProgressCard(
                    completedActivities: completedActivities,
                    totalActivities: totalActivities,
                    completedTodos: completedTodos,
                    totalTodos: totalTodos,
                  ),
                  const SizedBox(height: 20),

                  // ── NOW ──────────────────────────────────────────────────
                  if (nowActivity != null) ...[
                    _sectionLabel('NOW'),
                    const SizedBox(height: 8),
                    _NowCard(activity: nowActivity),
                    const SizedBox(height: 20),
                  ],

                  // ── UP NEXT ──────────────────────────────────────────────
                  if (upNext != null) ...[
                    _sectionLabel('UP NEXT'),
                    const SizedBox(height: 8),
                    _UpNextCard(activity: upNext, nowMins: nowMins),
                    const SizedBox(height: 20),
                  ],



                  // ── TO DO ────────────────────────────────────────────────
                  _HomeTodoSection(todos: todos, ref: ref),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Progress Card ──────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completedActivities,
    required this.totalActivities,
    required this.completedTodos,
    required this.totalTodos,
  });
  final int completedActivities;
  final int totalActivities;
  final int completedTodos;
  final int totalTodos;

  @override
  Widget build(BuildContext context) {
    final activityProgress = totalActivities == 0 ? 0.0 : completedActivities / totalActivities;
    final todoProgress = totalTodos == 0 ? 0.0 : completedTodos / totalTodos;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProgressSection(
                  title: 'Activities',
                  completed: completedActivities,
                  total: totalActivities,
                  progress: activityProgress,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _ProgressSection(
                  title: 'To-dos',
                  completed: completedTodos,
                  total: totalTodos,
                  progress: todoProgress,
                  icon: Icons.check_box_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.title,
    required this.completed,
    required this.total,
    required this.progress,
    required this.icon,
  });

  final String title;
  final int completed;
  final int total;
  final double progress;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$completed/$total completed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── NOW Card ───────────────────────────────────────────────────────────────────

class _NowCard extends StatelessWidget {
  const _NowCard({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    final mLeft = minutesLeft(activity.endTime);
    final s = parseTod(activity.startTime);
    final e = parseTod(activity.endTime);
    final totalMins =
        (e.hour * 60 + e.minute) - (s.hour * 60 + s.minute);
    final elapsed = totalMins - mLeft;
    final prog =
        totalMins > 0 ? (elapsed / totalMins).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(
                        '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                mLeft > 0 ? '$mLeft min left' : 'Ending',
                style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: prog,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Up Next Card ───────────────────────────────────────────────────────────────

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({required this.activity, required this.nowMins});
  final PlannerActivity activity;
  final int nowMins;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
    final s = parseTod(activity.startTime);
    final startsIn = (s.hour * 60 + s.minute) - nowMins;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(
            startsIn > 0 ? 'Starts in $startsIn min' : 'Starting',
            style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}



// ── Home Todo Section ──────────────────────────────────────────────────────────

class _HomeTodoSection extends StatelessWidget {
  const _HomeTodoSection({required this.todos, required this.ref});
  final List<DayTodo> todos;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final unchecked = todos.where((t) => !t.isCompleted).toList();
    final displayedTodos = unchecked.isNotEmpty ? unchecked : todos;

    final showViewAll = displayedTodos.length > 3;
    final todosToShow = showViewAll ? displayedTodos.take(3).toList() : displayedTodos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayedTodos.isEmpty ? 'TO DO' : 'TO DO (${displayedTodos.length})',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/day?expand_todo=true'),
              child: Text(showViewAll ? 'View All' : 'View',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (displayedTodos.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_box_outline_blank_rounded,
                    color: AppColors.textMuted, size: 18),
                SizedBox(width: 10),
                Text('No to-dos for today',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          )
        else ...[
          ...todosToShow.map((todo) => _HomeTodoRow(
                todo: todo,
                onToggle: () => ref
                    .read(plannerRepositoryProvider)
                    .toggleTodo(todo.id, todo.isCompleted, targetDate: DateTime.now()),
              )),
        ],
      ],
    );
  }
}

class _HomeTodoRow extends StatelessWidget {
  const _HomeTodoRow({
    required this.todo,
    required this.onToggle,
  });
  final DayTodo todo;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
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
                          color: AppColors.green, size: 13)
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
                    fontSize: 13,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
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
