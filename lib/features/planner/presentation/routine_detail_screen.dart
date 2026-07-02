import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/tables/planner_table.dart';
import '../providers/planner_providers.dart';
import '../utils/planner_utils.dart';

class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(routineBlocksProvider(routine.id));
    final (color, icon) = categoryStyle(routine.category);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(routine.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.card,
            onSelected: (v) async {
              if (v == 'delete') {
                await ref
                    .read(plannerRepositoryProvider)
                    .deleteRoutine(routine.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      color: AppColors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _scheduleLabel(routine.schedule),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: blocksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error loading blocks')),
              data: (blocks) {
                if (blocks.isEmpty) {
                  return const Center(
                    child: Text('No activities in this routine',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  itemCount: blocks.length,
                  itemBuilder: (_, i) => _RoutineBlockTile(block: blocks[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final blocks = blocksAsync.value;
                if (blocks == null || blocks.isEmpty) return;
                final repo = ref.read(plannerRepositoryProvider);
                await repo.applyRoutineToDate(blocks, dateOnly(DateTime.now()));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Routine applied to today!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Apply to Today',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(String s) => switch (s) {
        'weekdays' => 'Weekdays',
        'weekends' => 'Weekends',
        _ => 'Any day',
      };
}

class _RoutineBlockTile extends StatelessWidget {
  const _RoutineBlockTile({required this.block});
  final RoutineBlock block;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(block.category);
    final endMins = block.durationMinutes;
    final s = block.startTime.split(':');
    final totalMins =
        int.parse(s[0]) * 60 + int.parse(s[1]) + endMins;
    final endH = totalMins ~/ 60;
    final endM = totalMins % 60;
    final endStr =
        '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              displayTime(block.startTime),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Container(
            width: 36,
            height: 36,
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
                Text(block.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(
                  '${displayTime(block.startTime)} – ${displayTime(endStr)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            endMins >= 60
                ? '${endMins ~/ 60}h'
                : '${endMins}m',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
