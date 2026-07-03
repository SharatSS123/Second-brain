import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/planner_repository.dart';

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
