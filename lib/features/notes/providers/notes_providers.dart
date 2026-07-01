import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/notes_repository.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(appDatabaseProvider));
});

final allNotesProvider = StreamProvider.autoDispose<List<NotesTableData>>((ref) {
  return ref.watch(notesRepositoryProvider).watchAll();
});

final pinnedNotesProvider = StreamProvider.autoDispose<List<NotesTableData>>((ref) {
  return ref.watch(notesRepositoryProvider).watchPinned();
});
