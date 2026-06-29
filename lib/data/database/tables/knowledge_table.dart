import 'package:drift/drift.dart';

class KnowledgeTable extends Table {
  @override
  String get tableName => 'knowledge';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get type => text()(); // Link, Note, Code, Idea, Image
  TextColumn get content => text().nullable()(); // url or text content
  TextColumn get snippet => text().nullable()(); // code snippet or excerpt
  TextColumn get tags => text().nullable()(); // JSON encoded list
  TextColumn get source => text().nullable()(); // origin url or app
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
