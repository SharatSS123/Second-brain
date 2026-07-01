import 'package:drift/drift.dart';
import '../database/app_database.dart';

class TasksRepository {
  final AppDatabase _db;
  TasksRepository(this._db);

  Stream<List<TasksTableData>> watchAll() {
    return (_db.select(_db.tasksTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<TasksTableData>> watchByCompleted(bool completed) {
    return (_db.select(_db.tasksTable)
          ..where((t) => t.isCompleted.equals(completed))
          ..orderBy([(t) => OrderingTerm.desc(t.dueDate)]))
        .watch();
  }

  Future<void> add({
    required String title,
    String? description,
    String priority = 'Medium',
    DateTime? dueDate,
    bool isRecurring = false,
    String? recurringPattern,
  }) {
    return _db.into(_db.tasksTable).insert(
          TasksTableCompanion.insert(
            title: title,
            description: Value(description),
            priority: Value(priority),
            dueDate: Value(dueDate),
            isRecurring: Value(isRecurring),
            recurringPattern: Value(recurringPattern),
          ),
        );
  }

  Future<void> toggleComplete(int id, bool isCompleted) {
    return (_db.update(_db.tasksTable)..where((t) => t.id.equals(id)))
        .write(TasksTableCompanion(
          isCompleted: Value(isCompleted),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.tasksTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> update(
    int id, {
    required String title,
    String? description,
    String? priority,
    DateTime? dueDate,
  }) {
    return (_db.update(_db.tasksTable)..where((t) => t.id.equals(id)))
        .write(TasksTableCompanion(
          title: Value(title),
          description: Value(description),
          priority: priority == null ? const Value.absent() : Value(priority),
          dueDate: Value(dueDate),
          updatedAt: Value(DateTime.now()),
        ));
  }
}
