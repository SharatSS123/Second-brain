import 'package:drift/drift.dart';

@DataClassName('DayTodo')
class DayTodosTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get checklistId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
