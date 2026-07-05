import 'package:drift/drift.dart';

@DataClassName('Checklist')
class ChecklistsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

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

  @override
  Set<Column> get primaryKey => {id};
}
