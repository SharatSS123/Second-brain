import 'package:drift/drift.dart';

@DataClassName('Checklist')
class ChecklistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get iconKey => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('my_lists'))(); // my_lists, shared, archived

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChecklistItem')
class ChecklistItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get checklistId => text()();
  TextColumn get title => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get priority => text().nullable()(); // low, medium, high
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
