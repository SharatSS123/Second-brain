import 'package:drift/drift.dart';

class LearningTopicsTable extends Table {
  @override
  String get tableName => 'learning_topics';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get progressPercent => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class LearningResourcesTable extends Table {
  @override
  String get tableName => 'learning_resources';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().references(LearningTopicsTable, #id)();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get type => text()(); // Course, Article, Video, Book, Podcast
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get rating => integer().nullable()(); // 1-5
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
