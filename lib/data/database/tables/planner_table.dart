import 'package:drift/drift.dart';

@DataClassName('PlannerActivity')
class PlannerActivitiesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get category => text().withDefault(const Constant('Personal'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get description => text().nullable()();
  IntColumn get reminderMinutes => integer().nullable()();
  TextColumn get repeatType => text().withDefault(const Constant('none'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimeBlock')
class TimeBlocksTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get category => text().withDefault(const Constant('Work'))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Routine')
class RoutinesTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get schedule => text().withDefault(const Constant('any'))();
  TextColumn get category => text().withDefault(const Constant('Personal'))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoutineBlock')
class RoutineBlocksTable extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text()();
  TextColumn get title => text()();
  TextColumn get startTime => text()();
  IntColumn get durationMinutes => integer()();
  TextColumn get category => text().withDefault(const Constant('Personal'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
