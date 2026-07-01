import 'package:drift/drift.dart';
import '../database/app_database.dart';

class KnowledgeRepository {
  final AppDatabase _db;
  KnowledgeRepository(this._db);

  Stream<List<KnowledgeTableData>> watchAll() {
    return (_db.select(_db.knowledgeTable)
          ..orderBy([(k) => OrderingTerm.desc(k.createdAt)]))
        .watch();
  }

  Stream<List<KnowledgeTableData>> watchByType(String type) {
    return (_db.select(_db.knowledgeTable)
          ..where((k) => k.type.equals(type))
          ..orderBy([(k) => OrderingTerm.desc(k.createdAt)]))
        .watch();
  }

  Stream<List<KnowledgeTableData>> watchFavorites() {
    return (_db.select(_db.knowledgeTable)
          ..where((k) => k.isFavorite.equals(true))
          ..orderBy([(k) => OrderingTerm.desc(k.createdAt)]))
        .watch();
  }

  Future<void> add({
    required String title,
    required String type,
    String? content,
    String? snippet,
    String? source,
    List<String> tags = const [],
  }) {
    return _db.into(_db.knowledgeTable).insert(
          KnowledgeTableCompanion.insert(
            title: title,
            type: type,
            content: Value(content),
            snippet: Value(snippet),
            source: Value(source),
            tags: Value(tags.isNotEmpty ? tags.join(',') : null),
          ),
        );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) {
    return (_db.update(_db.knowledgeTable)..where((k) => k.id.equals(id)))
        .write(KnowledgeTableCompanion(isFavorite: Value(isFavorite)));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.knowledgeTable)..where((k) => k.id.equals(id))).go();
  }
}
