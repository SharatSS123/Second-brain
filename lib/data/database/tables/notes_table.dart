import 'package:drift/drift.dart';

class NotesTable extends Table {
  @override
  String get tableName => 'notes';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get tags => text().nullable()(); // JSON encoded list
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().nullable()(); // hex color string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
