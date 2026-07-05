import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/planner_repository.dart';
import '../utils/planner_utils.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(ref.watch(appDatabaseProvider));
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final todayActivitiesProvider = StreamProvider<List<PlannerActivity>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(plannerRepositoryProvider).watchActivitiesForDate(date);
});

final monthActivitiesProvider = StreamProvider<List<PlannerActivity>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref
      .watch(plannerRepositoryProvider)
      .watchActivitiesForMonth(month.year, month.month);
});

final upcomingActivitiesProvider = StreamProvider<List<PlannerActivity>>((ref) {
  return ref.watch(plannerRepositoryProvider).watchUpcomingActivities();
});

final completedActivitiesProvider =
    StreamProvider<List<PlannerActivity>>((ref) {
  return ref.watch(plannerRepositoryProvider).watchCompletedActivities();
});

final timeBlocksProvider = StreamProvider<List<TimeBlock>>((ref) {
  return ref.watch(plannerRepositoryProvider).watchTimeBlocks();
});

final routinesProvider = StreamProvider<List<Routine>>((ref) {
  return ref.watch(plannerRepositoryProvider).watchRoutines();
});

final routineBlocksProvider =
    StreamProvider.family<List<RoutineBlock>, String>((ref, routineId) {
  return ref.watch(plannerRepositoryProvider).watchRoutineBlocks(routineId);
});

final activitySubtasksProvider =
    StreamProvider.autoDispose.family<List<ActivitySubtask>, String>(
        (ref, activityId) {
  return ref.watch(plannerRepositoryProvider).watchSubtasks(activityId);
});

final liveActivityProvider = StreamProvider.autoDispose<PlannerActivity?>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref
      .watch(plannerRepositoryProvider)
      .watchActivitiesForDate(today)
      .map((list) => list.where((a) => isActiveNow(a.startTime, a.endTime) && !a.isCompleted).firstOrNull);
});

final todayTodosProvider = StreamProvider<List<DayTodo>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref.watch(plannerRepositoryProvider).watchTodosForDate(date);
});

final homeTodayActivitiesProvider = StreamProvider.autoDispose<List<PlannerActivity>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(plannerRepositoryProvider).watchActivitiesForDate(today);
});

final homeTodayTodosProvider = StreamProvider.autoDispose<List<DayTodo>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return ref.watch(plannerRepositoryProvider).watchTodosForDate(today);
});
