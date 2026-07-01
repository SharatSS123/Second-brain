import 'package:drift/drift.dart';
import '../database/app_database.dart';

class LearningRepository {
  final AppDatabase _db;
  LearningRepository(this._db);

  Stream<List<LearningTopicsTableData>> watchTopics() {
    return (_db.select(_db.learningTopicsTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<LearningResourcesTableData>> watchResourcesByTopic(int topicId) {
    return (_db.select(_db.learningResourcesTable)
          ..where((r) => r.topicId.equals(topicId))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  Future<List<LearningResourcesTableData>> getResourcesByTopic(int topicId) {
    return (_db.select(_db.learningResourcesTable)
          ..where((r) => r.topicId.equals(topicId)))
        .get();
  }

  Future<int> addTopic({
    required String name,
    String? description,
    String? color,
  }) {
    return _db.into(_db.learningTopicsTable).insert(
          LearningTopicsTableCompanion.insert(
            name: name,
            description: Value(description),
            color: Value(color),
          ),
        );
  }

  Future<int> addResource({
    required int topicId,
    required String title,
    required String type,
    String? url,
    String? notes,
  }) {
    return _db.into(_db.learningResourcesTable).insert(
          LearningResourcesTableCompanion.insert(
            topicId: topicId,
            title: title,
            type: type,
            url: Value(url),
            notes: Value(notes),
          ),
        );
  }

  Future<void> updateTopicProgress(int id, int percent) {
    return (_db.update(_db.learningTopicsTable)..where((t) => t.id.equals(id)))
        .write(LearningTopicsTableCompanion(
      progressPercent: Value(percent.clamp(0, 100)),
    ));
  }

  Future<void> toggleResourceComplete(int id, bool isCompleted) {
    return (_db.update(_db.learningResourcesTable)..where((r) => r.id.equals(id)))
        .write(LearningResourcesTableCompanion(isCompleted: Value(isCompleted)));
  }

  Future<void> deleteTopic(int id) async {
    await (_db.delete(_db.learningResourcesTable)..where((r) => r.topicId.equals(id))).go();
    await (_db.delete(_db.learningTopicsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteResource(int id) {
    return (_db.delete(_db.learningResourcesTable)..where((r) => r.id.equals(id))).go();
  }
}
