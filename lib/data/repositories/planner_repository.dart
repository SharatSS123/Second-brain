import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/tables/planner_table.dart';

class PlannerRepository {
  PlannerRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── Activities ────────────────────────────────────────────────────────────

  Stream<List<PlannerActivity>> watchActivitiesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return ((_db.select(_db.plannerActivitiesTable)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch());
  }

  Stream<List<PlannerActivity>> watchActivitiesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return ((_db.select(_db.plannerActivitiesTable)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch());
  }

  Stream<List<PlannerActivity>> watchUpcomingActivities() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    return ((_db.select(_db.plannerActivitiesTable)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.isCompleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch());
  }

  Stream<List<PlannerActivity>> watchCompletedActivities() {
    return ((_db.select(_db.plannerActivitiesTable)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch());
  }

  Future<void> addActivity({
    required String title,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String category,
    String? description,
    int? reminderMinutes,
    String repeatType = 'none',
  }) {
    return _db.into(_db.plannerActivitiesTable).insert(
          PlannerActivitiesTableCompanion.insert(
            id: _uuid.v4(),
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            category: Value(category),
            description: Value(description),
            reminderMinutes: Value(reminderMinutes),
            repeatType: Value(repeatType),
          ),
        );
  }

  Future<void> toggleComplete(String id, bool current) {
    return (_db.update(_db.plannerActivitiesTable)
          ..where((t) => t.id.equals(id)))
        .write(PlannerActivitiesTableCompanion(
            isCompleted: Value(!current)));
  }

  Future<void> deleteActivity(String id) {
    return (_db.delete(_db.plannerActivitiesTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Time Blocks ───────────────────────────────────────────────────────────

  Stream<List<TimeBlock>> watchTimeBlocks() {
    return (_db.select(_db.timeBlocksTable)
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<void> addTimeBlock({
    required String name,
    required String startTime,
    required String endTime,
    required String category,
    String frequency = 'daily',
    String? description,
  }) {
    return _db.into(_db.timeBlocksTable).insert(
          TimeBlocksTableCompanion.insert(
            id: _uuid.v4(),
            name: name,
            startTime: startTime,
            endTime: endTime,
            category: Value(category),
            frequency: Value(frequency),
            description: Value(description),
          ),
        );
  }

  Future<void> deleteTimeBlock(String id) {
    return (_db.delete(_db.timeBlocksTable)..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Routines ──────────────────────────────────────────────────────────────

  Stream<List<Routine>> watchRoutines() {
    return (_db.select(_db.routinesTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<RoutineBlock>> watchRoutineBlocks(String routineId) {
    return (_db.select(_db.routineBlocksTable)
          ..where((t) => t.routineId.equals(routineId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<String> addRoutine({
    required String name,
    required String schedule,
    required String category,
    String? description,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.routinesTable).insert(
          RoutinesTableCompanion.insert(
            id: id,
            name: name,
            schedule: Value(schedule),
            category: Value(category),
            description: Value(description),
          ),
        );
    return id;
  }

  Future<void> updateRoutine(
    String id, {
    String? name,
    String? schedule,
    String? category,
    String? description,
  }) {
    return (_db.update(_db.routinesTable)..where((t) => t.id.equals(id)))
        .write(RoutinesTableCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      schedule: schedule != null ? Value(schedule) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      description:
          description != null ? Value(description) : const Value.absent(),
    ));
  }

  Future<void> deleteRoutineBlock(String id) {
    return (_db.delete(_db.routineBlocksTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> updateRoutineBlockOrder(String id, int sortOrder) {
    return (_db.update(_db.routineBlocksTable)
          ..where((t) => t.id.equals(id)))
        .write(RoutineBlocksTableCompanion(sortOrder: Value(sortOrder)));
  }

  Future<void> addRoutineBlock({
    required String routineId,
    required String title,
    required String startTime,
    required int durationMinutes,
    required String category,
    required int sortOrder,
  }) {
    return _db.into(_db.routineBlocksTable).insert(
          RoutineBlocksTableCompanion.insert(
            id: _uuid.v4(),
            routineId: routineId,
            title: title,
            startTime: startTime,
            durationMinutes: durationMinutes,
            category: Value(category),
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<void> deleteRoutine(String id) async {
    await (_db.delete(_db.routineBlocksTable)
          ..where((t) => t.routineId.equals(id)))
        .go();
    await (_db.delete(_db.routinesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> applyRoutineToDate(
      List<RoutineBlock> blocks, DateTime date) async {
    for (final b in blocks) {
      final endMins = b.durationMinutes;
      final s = b.startTime.split(':');
      final startH = int.parse(s[0]);
      final startM = int.parse(s[1]);
      final totalEnd = startH * 60 + startM + endMins;
      final endH = totalEnd ~/ 60;
      final endM = totalEnd % 60;
      final endTime =
          '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
      await addActivity(
        title: b.title,
        date: date,
        startTime: b.startTime,
        endTime: endTime,
        category: b.category,
      );
    }
  }
}
