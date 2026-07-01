import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/tasks_repository.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(ref.watch(appDatabaseProvider));
});

final allTasksProvider = StreamProvider.autoDispose<List<TasksTableData>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchAll();
});

final pendingTasksProvider = StreamProvider.autoDispose<List<TasksTableData>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchByCompleted(false);
});

final completedTasksProvider = StreamProvider.autoDispose<List<TasksTableData>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchByCompleted(true);
});

final todayTasksProvider = StreamProvider.autoDispose<List<TasksTableData>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchToday();
});

final upcomingTasksProvider = StreamProvider.autoDispose<List<TasksTableData>>((ref) {
  return ref.watch(tasksRepositoryProvider).watchUpcoming();
});
