import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/checklists_repository.dart';

final checklistsRepositoryProvider = Provider<ChecklistsRepository>((ref) {
  return ChecklistsRepository(ref.watch(appDatabaseProvider));
});

final checklistsProvider = StreamProvider<List<Checklist>>((ref) {
  return ref.watch(checklistsRepositoryProvider).watchAll();
});

final checklistItemsProvider = StreamProvider.family<List<ChecklistItem>, String>((ref, checklistId) {
  return ref.watch(checklistsRepositoryProvider).watchItems(checklistId);
});
