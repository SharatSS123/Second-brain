import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/tables/planner_table.dart';

class PlannerRepository {
  PlannerRepository(this._db);
  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── Activities ────────────────────────────────────────────────────────────

  bool _doesActivityRecurOnDateBypassingLimit(PlannerActivity activity, DateTime targetDate) {
    final startDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
    final queryDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    if (queryDate.isBefore(startDate)) return false;
    
    if (activity.repeatEndsOn != null) {
      final endDate = DateTime(activity.repeatEndsOn!.year, activity.repeatEndsOn!.month, activity.repeatEndsOn!.day);
      if (queryDate.isAfter(endDate)) return false;
    }
    
    final differenceInDays = queryDate.difference(startDate).inDays;
    final interval = activity.repeatInterval > 0 ? activity.repeatInterval : 1;

    switch (activity.repeatType) {
      case 'daily':
        return differenceInDays % interval == 0;
        
      case 'weekdays':
        if (queryDate.weekday == DateTime.saturday || queryDate.weekday == DateTime.sunday) {
          return false;
        }
        return true;
        
      case 'weekly':
        if (queryDate.weekday != startDate.weekday) return false;
        final differenceInWeeks = (differenceInDays / 7).round();
        return differenceInWeeks % interval == 0;
        
      case 'monthly':
        if (queryDate.day != startDate.day) return false;
        final differenceInMonths = (queryDate.year - startDate.year) * 12 + (queryDate.month - startDate.month);
        return differenceInMonths % interval == 0;
        
      case 'custom':
        if (activity.repeatDaysOfWeek != null && activity.repeatDaysOfWeek!.isNotEmpty) {
          final days = activity.repeatDaysOfWeek!.split(',').map(int.parse).toList();
          if (!days.contains(queryDate.weekday)) return false;
          
          final startOfWeekStart = startDate.subtract(Duration(days: startDate.weekday - 1));
          final startOfWeekQuery = queryDate.subtract(Duration(days: queryDate.weekday - 1));
          final weeksDiff = (startOfWeekQuery.difference(startOfWeekStart).inDays / 7).round();
          return weeksDiff % interval == 0;
        } else {
          return differenceInDays % interval == 0;
        }
        
      default:
        return false;
    }
  }

  int _getOccurrenceCountUpTo(PlannerActivity activity, DateTime queryDate) {
    final startDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
    final end = DateTime(queryDate.year, queryDate.month, queryDate.day);
    int count = 0;
    
    DateTime current = startDate;
    while (!current.isAfter(end)) {
      if (_doesActivityRecurOnDateBypassingLimit(activity, current)) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  bool doesActivityRecurOnDate(PlannerActivity activity, DateTime targetDate) {
    final startDate = DateTime(activity.date.year, activity.date.month, activity.date.day);
    final queryDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    if (queryDate.isBefore(startDate)) return false;
    
    if (activity.repeatEndsOn != null) {
      final endDate = DateTime(activity.repeatEndsOn!.year, activity.repeatEndsOn!.month, activity.repeatEndsOn!.day);
      if (queryDate.isAfter(endDate)) return false;
    }
    
    if (activity.repeatEndsAfter != null) {
      final occurrences = _getOccurrenceCountUpTo(activity, queryDate);
      if (occurrences > activity.repeatEndsAfter!) return false;
    }
    
    return _doesActivityRecurOnDateBypassingLimit(activity, queryDate);
  }

  Stream<List<PlannerActivity>> watchActivitiesForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _db.select(_db.plannerActivitiesTable).watch().map((allActivities) {
      final List<PlannerActivity> instances = [];
      
      final nonRecurring = allActivities.where((a) => a.repeatType == 'none' && a.recurrenceParentId == null).toList();
      final masters = allActivities.where((a) => a.repeatType != 'none' && a.recurrenceParentId == null).toList();
      final exceptions = allActivities.where((a) => a.recurrenceParentId != null).toList();
      
      for (final a in nonRecurring) {
        if (a.date.year == targetDate.year && a.date.month == targetDate.month && a.date.day == targetDate.day) {
          instances.add(a);
        }
      }
      
      final exceptionsForToday = exceptions.where((e) => e.recurrenceExceptionDate != null && 
          e.recurrenceExceptionDate!.year == targetDate.year &&
          e.recurrenceExceptionDate!.month == targetDate.month &&
          e.recurrenceExceptionDate!.day == targetDate.day).toList();
      
      for (final e in exceptionsForToday) {
        if (!e.isDeleted) {
          instances.add(e);
        }
      }
      
      for (final master in masters) {
        final hasException = exceptionsForToday.any((e) => e.recurrenceParentId == master.id);
        if (hasException) continue;
        
        if (doesActivityRecurOnDate(master, targetDate)) {
          instances.add(
            PlannerActivity(
              id: '${master.id}_${targetDate.millisecondsSinceEpoch}',
              title: master.title,
              date: targetDate,
              startTime: master.startTime,
              endTime: master.endTime,
              category: master.category,
              isCompleted: master.isCompleted,
              description: master.description,
              reminderMinutes: master.reminderMinutes,
              repeatType: master.repeatType,
              repeatInterval: master.repeatInterval,
              repeatDaysOfWeek: master.repeatDaysOfWeek,
              repeatEndsOn: master.repeatEndsOn,
              repeatEndsAfter: master.repeatEndsAfter,
              recurrenceParentId: master.id,
              recurrenceExceptionDate: targetDate,
              isDeleted: false,
              createdAt: master.createdAt,
            ),
          );
        }
      }
      
      instances.sort((a, b) => a.startTime.compareTo(b.startTime));
      return instances;
    });
  }

  Stream<List<PlannerActivity>> watchActivitiesForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return _db.select(_db.plannerActivitiesTable).watch().map((allActivities) {
      final List<PlannerActivity> instances = [];
      DateTime current = start;
      while (current.isBefore(end)) {
        final targetDate = current;
        final nonRecurring = allActivities.where((a) => a.repeatType == 'none' && a.recurrenceParentId == null).toList();
        final masters = allActivities.where((a) => a.repeatType != 'none' && a.recurrenceParentId == null).toList();
        final exceptions = allActivities.where((a) => a.recurrenceParentId != null).toList();
        
        for (final a in nonRecurring) {
          if (a.date.year == targetDate.year && a.date.month == targetDate.month && a.date.day == targetDate.day) {
            instances.add(a);
          }
        }
        
        final exceptionsForToday = exceptions.where((e) => e.recurrenceExceptionDate != null && 
            e.recurrenceExceptionDate!.year == targetDate.year &&
            e.recurrenceExceptionDate!.month == targetDate.month &&
            e.recurrenceExceptionDate!.day == targetDate.day).toList();
        
        for (final e in exceptionsForToday) {
          if (!e.isDeleted) {
            instances.add(e);
          }
        }
        
        for (final master in masters) {
          final hasException = exceptionsForToday.any((e) => e.recurrenceParentId == master.id);
          if (hasException) continue;
          
          if (doesActivityRecurOnDate(master, targetDate)) {
            instances.add(
              PlannerActivity(
                id: '${master.id}_${targetDate.millisecondsSinceEpoch}',
                title: master.title,
                date: targetDate,
                startTime: master.startTime,
                endTime: master.endTime,
                category: master.category,
                isCompleted: master.isCompleted,
                description: master.description,
                reminderMinutes: master.reminderMinutes,
                repeatType: master.repeatType,
                repeatInterval: master.repeatInterval,
                repeatDaysOfWeek: master.repeatDaysOfWeek,
                repeatEndsOn: master.repeatEndsOn,
                repeatEndsAfter: master.repeatEndsAfter,
                recurrenceParentId: master.id,
                recurrenceExceptionDate: targetDate,
                isDeleted: false,
                createdAt: master.createdAt,
              ),
            );
          }
        }
        current = current.add(const Duration(days: 1));
      }
      
      instances.sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        return a.startTime.compareTo(b.startTime);
      });
      return instances;
    });
  }

  Stream<List<PlannerActivity>> watchUpcomingActivities() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final start = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    return _db.select(_db.plannerActivitiesTable).watch().map((allActivities) {
      final List<PlannerActivity> instances = [];
      DateTime current = start;
      final maxFutureDate = start.add(const Duration(days: 30));
      while (current.isBefore(maxFutureDate)) {
        final targetDate = current;
        final nonRecurring = allActivities.where((a) => a.repeatType == 'none' && a.recurrenceParentId == null).toList();
        final masters = allActivities.where((a) => a.repeatType != 'none' && a.recurrenceParentId == null).toList();
        final exceptions = allActivities.where((a) => a.recurrenceParentId != null).toList();
        
        for (final a in nonRecurring) {
          if (a.date.year == targetDate.year && a.date.month == targetDate.month && a.date.day == targetDate.day && !a.isCompleted) {
            instances.add(a);
          }
        }
        
        final exceptionsForToday = exceptions.where((e) => e.recurrenceExceptionDate != null && 
            e.recurrenceExceptionDate!.year == targetDate.year &&
            e.recurrenceExceptionDate!.month == targetDate.month &&
            e.recurrenceExceptionDate!.day == targetDate.day).toList();
        
        for (final e in exceptionsForToday) {
          if (!e.isDeleted && !e.isCompleted) {
            instances.add(e);
          }
        }
        
        for (final master in masters) {
          final hasException = exceptionsForToday.any((e) => e.recurrenceParentId == master.id);
          if (hasException) continue;
          
          if (doesActivityRecurOnDate(master, targetDate)) {
            instances.add(
              PlannerActivity(
                id: '${master.id}_${targetDate.millisecondsSinceEpoch}',
                title: master.title,
                date: targetDate,
                startTime: master.startTime,
                endTime: master.endTime,
                category: master.category,
                isCompleted: master.isCompleted,
                description: master.description,
                reminderMinutes: master.reminderMinutes,
                repeatType: master.repeatType,
                repeatInterval: master.repeatInterval,
                repeatDaysOfWeek: master.repeatDaysOfWeek,
                repeatEndsOn: master.repeatEndsOn,
                repeatEndsAfter: master.repeatEndsAfter,
                recurrenceParentId: master.id,
                recurrenceExceptionDate: targetDate,
                isDeleted: false,
                createdAt: master.createdAt,
              ),
            );
          }
        }
        current = current.add(const Duration(days: 1));
      }
      
      instances.sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        return a.startTime.compareTo(b.startTime);
      });
      return instances;
    });
  }

  Stream<List<PlannerActivity>> watchCompletedActivities() {
    return _db.select(_db.plannerActivitiesTable).watch().map((allActivities) {
      final List<PlannerActivity> instances = [];
      final completed = allActivities.where((a) => a.isCompleted && !a.isDeleted).toList();
      for (final a in completed) {
        instances.add(a);
      }
      instances.sort((a, b) {
        final dateComp = b.date.compareTo(a.date);
        if (dateComp != 0) return dateComp;
        return a.startTime.compareTo(b.startTime);
      });
      return instances;
    });
  }

  Future<PlannerActivity?> getActivityById(String id) {
    return (_db.select(_db.plannerActivitiesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
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
    int repeatInterval = 1,
    String? repeatDaysOfWeek,
    DateTime? repeatEndsOn,
    int? repeatEndsAfter,
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
            repeatInterval: Value(repeatInterval),
            repeatDaysOfWeek: Value(repeatDaysOfWeek),
            repeatEndsOn: Value(repeatEndsOn),
            repeatEndsAfter: Value(repeatEndsAfter),
          ),
        );
  }

  Future<void> toggleComplete(String id, bool current) async {
    if (id.contains('_')) {
      final parts = id.split('_');
      final parentId = parts[0];
      final timestamp = int.parse(parts[1]);
      final exceptionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

      final parent = await getActivityById(parentId);
      if (parent != null) {
        // If there's already an exception row for this date, toggle its completed state
        final existingException = await (_db.select(_db.plannerActivitiesTable)
              ..where((t) => 
                  t.recurrenceParentId.equals(parentId) & 
                  t.recurrenceExceptionDate.equals(exceptionDate)))
            .getSingleOrNull();

        if (existingException != null) {
          await (_db.update(_db.plannerActivitiesTable)..where((t) => t.id.equals(existingException.id)))
              .write(PlannerActivitiesTableCompanion(isCompleted: Value(!current)));
        } else {
          await _db.into(_db.plannerActivitiesTable).insert(
                PlannerActivitiesTableCompanion.insert(
                  id: _uuid.v4(),
                  title: parent.title,
                  date: exceptionDate,
                  startTime: parent.startTime,
                  endTime: parent.endTime,
                  category: Value(parent.category),
                  isCompleted: Value(!current),
                  description: Value(parent.description),
                  reminderMinutes: Value(parent.reminderMinutes),
                  repeatType: const Value('none'),
                  recurrenceParentId: Value(parentId),
                  recurrenceExceptionDate: Value(exceptionDate),
                ),
              );
        }
      }
      return;
    }

    await (_db.update(_db.plannerActivitiesTable)
          ..where((t) => t.id.equals(id)))
        .write(PlannerActivitiesTableCompanion(
            isCompleted: Value(!current)));
  }

  Future<void> deleteEntireSeries(String parentId) async {
    await (_db.delete(_db.plannerActivitiesTable)..where((t) => t.id.equals(parentId))).go();
    await (_db.delete(_db.plannerActivitiesTable)..where((t) => t.recurrenceParentId.equals(parentId))).go();
  }

  Future<void> deleteThisAndFuture(String parentId, DateTime date) async {
    final dayBefore = date.subtract(const Duration(days: 1));
    await (_db.update(_db.plannerActivitiesTable)..where((t) => t.id.equals(parentId)))
        .write(PlannerActivitiesTableCompanion(
          repeatEndsOn: Value(dayBefore),
        ));
    await (_db.delete(_db.plannerActivitiesTable)..where((t) => 
        t.recurrenceParentId.equals(parentId) & 
        t.recurrenceExceptionDate.isBiggerOrEqualValue(date))).go();
  }

  Future<void> deleteOccurrenceOnly(String parentId, DateTime date) async {
    final parent = await getActivityById(parentId);
    if (parent == null) return;
    
    await _db.into(_db.plannerActivitiesTable).insert(
      PlannerActivitiesTableCompanion.insert(
        id: _uuid.v4(),
        title: parent.title,
        date: date,
        startTime: parent.startTime,
        endTime: parent.endTime,
        category: Value(parent.category),
        isDeleted: const Value(true),
        repeatType: const Value('none'),
        recurrenceParentId: Value(parentId),
        recurrenceExceptionDate: Value(date),
      ),
    );
  }

  Future<void> editActivityWithScope({
    required String id,
    required String scope,
    required DateTime date,
    required String title,
    required String startTime,
    required String endTime,
    required String category,
    String? description,
    int? reminderMinutes,
    required String repeatType,
    int repeatInterval = 1,
    String? repeatDaysOfWeek,
    DateTime? repeatEndsOn,
    int? repeatEndsAfter,
  }) async {
    final isVirtual = id.contains('_');
    final parentId = isVirtual ? id.split('_')[0] : id;

    final parent = await getActivityById(parentId);
    if (parent == null) return;

    final effectiveScope = (parent.repeatType == 'none') ? 'entire' : scope;

    if (effectiveScope == 'entire') {
      await (_db.update(_db.plannerActivitiesTable)..where((t) => t.id.equals(parentId)))
          .write(PlannerActivitiesTableCompanion(
            title: Value(title),
            startTime: Value(startTime),
            endTime: Value(endTime),
            category: Value(category),
            description: Value(description),
            reminderMinutes: Value(reminderMinutes),
            repeatType: Value(repeatType),
            repeatInterval: Value(repeatInterval),
            repeatDaysOfWeek: Value(repeatDaysOfWeek),
            repeatEndsOn: Value(repeatEndsOn),
            repeatEndsAfter: Value(repeatEndsAfter),
          ));
    } else if (effectiveScope == 'this_and_future' || effectiveScope == 'future') {
      final dayBefore = date.subtract(const Duration(days: 1));
      await (_db.update(_db.plannerActivitiesTable)..where((t) => t.id.equals(parentId)))
          .write(PlannerActivitiesTableCompanion(
            repeatEndsOn: Value(dayBefore),
          ));

      await _db.into(_db.plannerActivitiesTable).insert(
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
          repeatInterval: Value(repeatInterval),
          repeatDaysOfWeek: Value(repeatDaysOfWeek),
          repeatEndsOn: Value(repeatEndsOn),
          repeatEndsAfter: Value(repeatEndsAfter),
        ),
      );

      await (_db.delete(_db.plannerActivitiesTable)..where((t) => 
          t.recurrenceParentId.equals(parentId) & 
          t.recurrenceExceptionDate.isBiggerOrEqualValue(date))).go();
    } else {
      final existingException = await (_db.select(_db.plannerActivitiesTable)
            ..where((t) => 
                t.recurrenceParentId.equals(parentId) & 
                t.recurrenceExceptionDate.equals(date)))
          .getSingleOrNull();

      if (existingException != null) {
        await (_db.update(_db.plannerActivitiesTable)..where((t) => t.id.equals(existingException.id)))
            .write(PlannerActivitiesTableCompanion(
              title: Value(title),
              startTime: Value(startTime),
              endTime: Value(endTime),
              category: Value(category),
              description: Value(description),
              reminderMinutes: Value(reminderMinutes),
              repeatType: const Value('none'),
            ));
      } else {
        await _db.into(_db.plannerActivitiesTable).insert(
          PlannerActivitiesTableCompanion.insert(
            id: _uuid.v4(),
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            category: Value(category),
            description: Value(description),
            reminderMinutes: Value(reminderMinutes),
            repeatType: const Value('none'),
            recurrenceParentId: Value(parentId),
            recurrenceExceptionDate: Value(date),
          ),
        );
      }
    }
  }

  Future<void> deleteActivity(String id) {
    if (id.contains('_')) {
      final parts = id.split('_');
      final parentId = parts[0];
      final timestamp = int.parse(parts[1]);
      final exceptionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return deleteOccurrenceOnly(parentId, exceptionDate);
    }
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

  // ── Activity Subtasks ─────────────────────────────────────────────────────

  Stream<List<ActivitySubtask>> watchSubtasks(String activityId) {
    return (_db.select(_db.activitySubtasksTable)
          ..where((t) => t.activityId.equals(activityId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> addSubtask({
    required String activityId,
    required String title,
    required int sortOrder,
  }) {
    return _db.into(_db.activitySubtasksTable).insert(
          ActivitySubtasksTableCompanion.insert(
            id: _uuid.v4(),
            activityId: activityId,
            title: title,
            sortOrder: Value(sortOrder),
          ),
        );
  }

  Future<void> toggleSubtask(String id, bool current) {
    return (_db.update(_db.activitySubtasksTable)
          ..where((t) => t.id.equals(id)))
        .write(ActivitySubtasksTableCompanion(isCompleted: Value(!current)));
  }

  Future<void> deleteSubtask(String id) {
    return (_db.delete(_db.activitySubtasksTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Day Todos ─────────────────────────────────────────────────────────────────

  Stream<List<DayTodo>> watchTodosForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.dayTodosTable)
          ..where((t) =>
              (t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)) |
              (t.date.isSmallerThanValue(start) & t.isCompleted.equals(false)))
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<void> addTodo({
    required String title,
    required DateTime date,
    String? checklistId,
  }) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final existing = await (_db.select(_db.dayTodosTable)
          ..where((t) =>
              (t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)) |
              (t.date.isSmallerThanValue(start) & t.isCompleted.equals(false))))
        .get();

    await _db.transaction(() async {
      for (final todo in existing) {
        await (_db.update(_db.dayTodosTable)..where((t) => t.id.equals(todo.id)))
            .write(DayTodosTableCompanion(sortOrder: Value(todo.sortOrder + 1)));
      }
      await _db.into(_db.dayTodosTable).insert(
        DayTodosTableCompanion.insert(
          id: _uuid.v4(),
          title: title,
          date: date,
          checklistId: Value(checklistId),
          sortOrder: const Value(0),
        ),
      );
    });
  }

  Future<void> toggleTodo(String id, bool current, {DateTime? targetDate}) {
    return (_db.update(_db.dayTodosTable)..where((t) => t.id.equals(id)))
        .write(DayTodosTableCompanion(
      isCompleted: Value(!current),
      date: targetDate != null && !current ? Value(targetDate) : const Value.absent(),
    ));
  }

  Future<void> deleteTodo(String id) {
    return (_db.delete(_db.dayTodosTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateTodo({
    required String id,
    required String title,
    required String? checklistId,
  }) {
    return (_db.update(_db.dayTodosTable)..where((t) => t.id.equals(id)))
        .write(DayTodosTableCompanion(
      title: Value(title),
      checklistId: Value(checklistId),
    ));
  }

  Future<void> updateTodosOrder(List<DayTodo> todos) async {
    await _db.transaction(() async {
      for (int i = 0; i < todos.length; i++) {
        await (_db.update(_db.dayTodosTable)..where((t) => t.id.equals(todos[i].id)))
            .write(DayTodosTableCompanion(sortOrder: Value(i)));
      }
    });
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
