import 'package:drift/drift.dart';

class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get priority => text().withDefault(const Constant('Medium'))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringPattern => text().nullable()(); // daily, weekly, monthly
  TextColumn get tags => text().nullable()(); // JSON encoded list
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
