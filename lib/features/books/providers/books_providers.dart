import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/books_repository.dart';

final toReadBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(booksRepositoryProvider).watchByStatus('to_read');
});

final readBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(booksRepositoryProvider).watchByStatus('read');
});
