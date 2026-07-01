import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/learning_repository.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(appDatabaseProvider));
});

final learningTopicsProvider =
    StreamProvider.autoDispose<List<LearningTopicsTableData>>((ref) {
  return ref.watch(learningRepositoryProvider).watchTopics();
});

final learningResourcesProvider = StreamProvider.autoDispose
    .family<List<LearningResourcesTableData>, int>((ref, topicId) {
  return ref.watch(learningRepositoryProvider).watchResourcesByTopic(topicId);
});
