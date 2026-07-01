import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/knowledge_repository.dart';

final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  return KnowledgeRepository(ref.watch(appDatabaseProvider));
});

final allKnowledgeProvider =
    StreamProvider.autoDispose<List<KnowledgeTableData>>((ref) {
  return ref.watch(knowledgeRepositoryProvider).watchAll();
});

final knowledgeByTypeProvider = StreamProvider.autoDispose
    .family<List<KnowledgeTableData>, String>((ref, type) {
  return ref.watch(knowledgeRepositoryProvider).watchByType(type);
});
