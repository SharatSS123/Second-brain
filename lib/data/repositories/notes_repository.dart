import 'package:drift/drift.dart';
import '../database/app_database.dart';

class NotesRepository {
  final AppDatabase _db;
  NotesRepository(this._db);

  Stream<List<NotesTableData>> watchAll() {
    return (_db.select(_db.notesTable)
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch();
  }

  Stream<List<NotesTableData>> watchPinned() {
    return (_db.select(_db.notesTable)
          ..where((n) => n.isPinned.equals(true))
          ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
        .watch();
  }

  Future<void> add({
    required String title,
    required String content,
    String? color,
    List<String> tags = const [],
  }) {
    return _db.into(_db.notesTable).insert(
          NotesTableCompanion.insert(
            title: title,
            content: Value(content),
            color: Value(color),
            tags: Value(tags.isNotEmpty ? tags.join(',') : null),
          ),
        );
  }

  Future<void> update(
    int id, {
    required String title,
    required String content,
    String? color,
  }) {
    return (_db.update(_db.notesTable)..where((n) => n.id.equals(id)))
        .write(NotesTableCompanion(
          title: Value(title),
          content: Value(content),
          color: Value(color),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> togglePin(int id, bool isPinned) {
    return (_db.update(_db.notesTable)..where((n) => n.id.equals(id)))
        .write(NotesTableCompanion(
          isPinned: Value(isPinned),
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.notesTable)..where((n) => n.id.equals(id))).go();
  }
}
