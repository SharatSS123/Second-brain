import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/tables/entertainment_table.dart';
import '../../../data/repositories/entertainment_repository.dart';

final entertainmentRepositoryProvider = Provider<EntertainmentRepository>((ref) {
  return EntertainmentRepository(ref.watch(appDatabaseProvider));
});

final movieWatchlistProvider = StreamProvider.autoDispose<List<EntertainmentItem>>((ref) {
  return ref.watch(entertainmentRepositoryProvider).watchByTypeAndStatus('Movie', 'Watchlist');
});

final watchedMoviesProvider = StreamProvider.autoDispose<List<EntertainmentItem>>((ref) {
  return ref.watch(entertainmentRepositoryProvider).watchByTypeAndStatus('Movie', 'Completed');
});

final seriesWatchlistProvider = StreamProvider.autoDispose<List<EntertainmentItem>>((ref) {
  return ref
      .watch(entertainmentRepositoryProvider)
      .watchByTypeAndStatus('TV Series', 'Watchlist');
});

final watchedSeriesProvider = StreamProvider.autoDispose<List<EntertainmentItem>>((ref) {
  return ref
      .watch(entertainmentRepositoryProvider)
      .watchByTypeAndStatus('TV Series', 'Completed');
});
