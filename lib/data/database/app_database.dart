import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/tasks_table.dart';
import 'tables/notes_table.dart';
import 'tables/learning_table.dart';
import 'tables/entertainment_table.dart';
import 'tables/knowledge_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  TasksTable,
  NotesTable,
  LearningTopicsTable,
  LearningResourcesTable,
  EntertainmentTable,
  KnowledgeTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'second_brain');
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override in main()');
});
