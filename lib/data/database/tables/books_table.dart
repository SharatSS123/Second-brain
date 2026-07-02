import 'package:drift/drift.dart';

@DataClassName('Book')
class BooksTable extends Table {
  @override
  String get tableName => 'books';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get author => text().nullable()();
  TextColumn get genre => text().nullable()();
  // 'to_read' | 'read'
  TextColumn get status => text().withDefault(const Constant('to_read'))();
  IntColumn get rating => integer().nullable()(); // 1–5
  TextColumn get notes => text().nullable()();
  IntColumn get totalPages => integer().nullable()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
