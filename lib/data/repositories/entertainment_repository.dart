import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../database/tables/entertainment_table.dart';

class EntertainmentRepository {
  final AppDatabase _db;
  EntertainmentRepository(this._db);

  Stream<List<EntertainmentItem>> watchByTypeAndStatus(String type, String status) {
    return (_db.select(_db.entertainmentTable)
          ..where((t) => t.type.equals(type) & t.status.equals(status))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<EntertainmentItem>> watchByType(String type) {
    return (_db.select(_db.entertainmentTable)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> add({
    required String title,
    required String type,
    String status = 'Watchlist',
    String? genre,
    int? year,
    String? notes,
    String? imageUrl,
  }) {
    return _db.into(_db.entertainmentTable).insert(
          EntertainmentTableCompanion.insert(
            title: title,
            type: type,
            status: Value(status),
            genre: Value(genre),
            year: Value(year),
            notes: Value(notes),
            imageUrl: Value(imageUrl),
          ),
        );
  }

  Future<void> markAsWatched(int id) {
    return (_db.update(_db.entertainmentTable)..where((t) => t.id.equals(id)))
        .write(EntertainmentTableCompanion(
      status: const Value('Completed'),
      completedAt: Value(DateTime.now()),
    ));
  }

  Future<void> moveToWatchlist(int id) {
    return (_db.update(_db.entertainmentTable)..where((t) => t.id.equals(id)))
        .write(const EntertainmentTableCompanion(
      status: Value('Watchlist'),
      completedAt: Value(null),
    ));
  }

  Future<void> updateRating(int id, int rating) {
    return (_db.update(_db.entertainmentTable)..where((t) => t.id.equals(id)))
        .write(EntertainmentTableCompanion(rating: Value(rating)));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.entertainmentTable)..where((t) => t.id.equals(id))).go();
  }

  Future<Map<String, int>> countByType() async {
    final all = await _db.select(_db.entertainmentTable).get();
    final counts = <String, int>{};
    for (final item in all) {
      counts[item.type] = (counts[item.type] ?? 0) + 1;
    }
    return counts;
  }
}
