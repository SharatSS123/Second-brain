import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/tables/books_table.dart';

class BooksRepository {
  BooksRepository(this._db);
  final AppDatabase _db;

  Stream<List<Book>> watchByStatus(String status) => (_db.select(_db.booksTable)
        ..where((b) => b.status.equals(status))
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
      .watch();

  Future<void> addBook({
    required String title,
    String? author,
    String? genre,
    required String status,
    int? rating,
    String? notes,
    int? totalPages,
  }) =>
      _db.into(_db.booksTable).insert(BooksTableCompanion.insert(
            title: title,
            author: Value(author),
            genre: Value(genre),
            status: Value(status),
            rating: Value(rating),
            notes: Value(notes),
            totalPages: Value(totalPages),
            finishedAt: Value(status == 'read' ? DateTime.now() : null),
          ));

  Future<void> updateStatus(int id, String status) =>
      (_db.update(_db.booksTable)..where((b) => b.id.equals(id))).write(
        BooksTableCompanion(
          status: Value(status),
          finishedAt: Value(status == 'read' ? DateTime.now() : null),
        ),
      );

  Future<void> updateRating(int id, int? rating) =>
      (_db.update(_db.booksTable)..where((b) => b.id.equals(id)))
          .write(BooksTableCompanion(rating: Value(rating)));

  Future<void> deleteBook(int id) =>
      (_db.delete(_db.booksTable)..where((b) => b.id.equals(id))).go();
}

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository(ref.watch(appDatabaseProvider));
});
