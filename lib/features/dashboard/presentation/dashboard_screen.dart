import 'dart:math';
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

    final total = activities.length;
    final completed = activities.where((a) => a.isCompleted).length;
    final inProgress = activities
        .where((a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted)
        .length;
    final progress = total == 0 ? 0.0 : completed / total;

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
    final laterToday =
        upcoming.length > 1 ? upcoming.sublist(1) : <PlannerActivity>[];

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
                    progress: progress,
                    completed: completed,
                    total: total,
                    inProgress: inProgress,
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

                  // ── LATER TODAY ──────────────────────────────────────────
                  if (laterToday.isNotEmpty) ...[
                    _sectionLabel('LATER TODAY'),
                    const SizedBox(height: 8),
                    ...laterToday.take(3).map((a) => _LaterRow(activity: a)),
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
    required this.progress,
    required this.completed,
    required this.total,
    required this.inProgress,
  });
  final double progress;
  final int completed;
  final int total;
  final int inProgress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Progress",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No activities planned'
                          : '$completed of $total activities completed',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _CircleProgressPainter(progress: progress),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(value: total, label: 'Total Activities'),
              const SizedBox(width: 8),
              _StatChip(
                  value: inProgress,
                  label: 'In Progress',
                  color: AppColors.amber),
              const SizedBox(width: 8),
              _StatChip(
                  value: completed,
                  label: 'Completed',
                  color: AppColors.green),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label, this.color});
  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress;
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

// ── Later Row ──────────────────────────────────────────────────────────────────

class _LaterRow extends StatelessWidget {
  const _LaterRow({required this.activity});
  final PlannerActivity activity;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(activity.category);
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(
                    '${displayTime(activity.startTime)} – ${displayTime(activity.endTime)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 18),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              todos.isEmpty ? 'TO DO' : 'TO DO (${todos.length})',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/day'),
              child: const Text('View',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (todos.isEmpty)
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
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                ...todos.map((todo) => _HomeTodoRow(
                      todo: todo,
                      onToggle: () => ref
                          .read(plannerRepositoryProvider)
                          .toggleTodo(todo.id, todo.isCompleted),
                      isLast: todo == todos.last,
                    )),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeTodoRow extends StatelessWidget {
  const _HomeTodoRow({
    required this.todo,
    required this.onToggle,
    required this.isLast,
  });
  final DayTodo todo;
  final VoidCallback onToggle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        if (!isLast)
          const Divider(
              height: 0,
              color: AppColors.divider,
              thickness: 0.5,
              indent: 46),
      ],
    );
  }
}
