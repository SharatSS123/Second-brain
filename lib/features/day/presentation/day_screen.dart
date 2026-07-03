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
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (_, __) =>
                        const Center(child: Text('Error loading')),
                    data: (activities) => activities.isEmpty
                        ? _EmptyDayView(selectedDate: selectedDate)
                        : _DayTimeline(activities: activities),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () => showAddActivitySheet(context, ref),
                backgroundColor: AppColors.primary,
                elevation: 4,
                child:
                    const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

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
          // Hamburger
          IconButton(
            icon: const Icon(Icons.menu_rounded,
                color: AppColors.textSecondary),
            onPressed: () =>
                mainScaffoldKey.currentState?.openDrawer(),
          ),

          // Day navigation
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
                            builder: (_) =>
                                const CalendarPickerScreen()),
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
                                    borderRadius:
                                        BorderRadius.circular(6),
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
                                color: AppColors.textMuted,
                                fontSize: 12),
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

          // Profile
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
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

// ── Timeline view ──────────────────────────────────────────────────────────

class _DayTimeline extends ConsumerWidget {
  const _DayTimeline({required this.activities});
  final List<PlannerActivity> activities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = activities
        .where((a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted);
    final currentActivity = active.isNotEmpty ? active.first : null;

    return CustomScrollView(
      slivers: [
        if (currentActivity != null)
          SliverToBoxAdapter(child: _NowCard(activity: currentActivity)),
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
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

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
      loading: () => _buildCard(context, timeProgress, null, null, mLeft),
      error: (_, __) => _buildCard(context, timeProgress, null, null, mLeft),
      data: (subtasks) {
        if (subtasks.isEmpty) {
          return _buildCard(context, timeProgress, null, null, mLeft);
        }
        final done = subtasks.where((s) => s.isCompleted).length;
        final subtaskProgress = done / subtasks.length;
        return _buildCard(context, subtaskProgress, done, subtasks.length, mLeft);
      },
    );
  }

  Widget _buildCard(BuildContext context, double progress, int? done, int? total, int mLeft) {
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
                Text(
                  '$done of $total done',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                )
              else
                Text(
                  mLeft > 0 ? '$mLeft min left' : 'Ending',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
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
          Row(children: [
            _badge('In Progress', green: true),
          ]),
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
            // Time column
            SizedBox(
              width: 64,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  displayTime(activity.startTime),
                  style: TextStyle(
                    color:
                        isNow ? AppColors.primary : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Spine
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
                    color:
                        isNow ? AppColors.primary : AppColors.border,
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
            // Card
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
                      // Complete toggle
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

class _ActivityQuickSheet extends ConsumerStatefulWidget {
  const _ActivityQuickSheet({required this.activity});
  final PlannerActivity activity;

  @override
  ConsumerState<_ActivityQuickSheet> createState() => _ActivityQuickSheetState();
}

class _ActivityQuickSheetState extends ConsumerState<_ActivityQuickSheet> {
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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

            // ── Subtasks section ──────────────────────────────────────────
            subtasksAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (subtasks) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtasks.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'TASKS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
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
                            ? subtasks.where((s) => s.isCompleted).length / subtasks.length
                            : 0,
                        minHeight: 3,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
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
                              padding: const EdgeInsets.only(right: 12),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.red, size: 18),
                            ),
                            onDismissed: (_) => ref
                                .read(plannerRepositoryProvider)
                                .deleteSubtask(sub.id),
                            child: InkWell(
                              onTap: () => ref
                                  .read(plannerRepositoryProvider)
                                  .toggleSubtask(sub.id, sub.isCompleted),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 7, horizontal: 2),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
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
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 12)
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
                        },
                      ),
                    ),
                  ],

                  // Add task row
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
                                  color: AppColors.textPrimary, fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Task name',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 8),
                                border: UnderlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addSubtask(subtasks),
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
                      onPressed: () => setState(() => _showAddField = true),
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

            // ── Action buttons ────────────────────────────────────────────
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
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(plannerRepositoryProvider)
                          .toggleComplete(activity.id, activity.isCompleted);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: Icon(
                      activity.isCompleted
                          ? Icons.undo_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(activity.isCompleted ? 'Undo' : 'Complete'),
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

// ── Empty day ──────────────────────────────────────────────────────────────

class _EmptyDayView extends ConsumerWidget {
  const _EmptyDayView({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(
                  Icons.event_available_rounded,
                  color: AppColors.primary.withValues(alpha: 0.6),
                  size: 56,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'No activities planned',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan your day or apply a template\nto get started.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 50,
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
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => showAddActivitySheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('+ Add Activity',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
