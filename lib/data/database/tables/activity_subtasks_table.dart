import 'package:drift/drift.dart';

@DataClassName('ActivitySubtask')
class ActivitySubtasksTable extends Table {
  TextColumn get id => text()();
  TextColumn get activityId => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
