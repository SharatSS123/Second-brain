import 'package:drift/drift.dart';

@DataClassName('EntertainmentItem')
class EntertainmentTable extends Table {
  @override
  String get tableName => 'entertainment';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get type => text()(); // Movie, TV Series, Anime, Book, Game
  TextColumn get status => text().withDefault(const Constant('Watchlist'))();
  // Watchlist, Watching, Completed, Dropped
  IntColumn get rating => integer().nullable()(); // 1-10
  TextColumn get notes => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
