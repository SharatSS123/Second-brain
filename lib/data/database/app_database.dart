import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/tasks_table.dart';
import 'tables/notes_table.dart';
import 'tables/learning_table.dart';
import 'tables/entertainment_table.dart';
import 'tables/books_table.dart';
import 'tables/knowledge_table.dart';
import 'tables/planner_table.dart';
import 'tables/activity_subtasks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TasksTable,
  NotesTable,
  LearningTopicsTable,
  LearningResourcesTable,
  EntertainmentTable,
  KnowledgeTable,
  BooksTable,
  PlannerActivitiesTable,
  TimeBlocksTable,
  RoutinesTable,
  RoutineBlocksTable,
  ActivitySubtasksTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(plannerActivitiesTable);
            await m.createTable(timeBlocksTable);
            await m.createTable(routinesTable);
            await m.createTable(routineBlocksTable);
          }
          if (from < 3) {
            await m.addColumn(routinesTable, routinesTable.description);
          }
          if (from < 4) {
            await m.createTable(booksTable);
          }
          if (from < 5) {
            await m.createTable(activitySubtasksTable);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'cortex');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override in main()');
});
