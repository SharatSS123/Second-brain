import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/books_repository.dart';
import '../providers/books_providers.dart';

const _kGenres = [
  'Fiction',
  'Non-Fiction',
  'Science Fiction',
  'Fantasy',
  'Mystery',
  'Thriller',
  'Romance',
  'History',
  'Biography',
  'Science',
  'Self-Help',
  'Other',
];

Color _genreColor(String? genre) => switch (genre) {
      'Fiction' => const Color(0xFF8B5CF6),
      'Non-Fiction' => const Color(0xFF06B6D4),
      'Science Fiction' => const Color(0xFF3B82F6),
      'Fantasy' => const Color(0xFFA855F7),
      'Mystery' => const Color(0xFF6366F1),
      'Thriller' => const Color(0xFFEF4444),
      'Romance' => const Color(0xFFEC4899),
      'History' => const Color(0xFFF59E0B),
      'Biography' => const Color(0xFF10B981),
      'Science' => const Color(0xFF14B8A6),
      'Self-Help' => const Color(0xFF22C55E),
      _ => const Color(0xFF64748B),
    };

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Books',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tc,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'To Read'),
                  Tab(text: 'Read'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [
          _BookList(status: 'to_read'),
          _BookList(status: 'read'),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBookSheet(ref: ref),
    );
  }
}

// ── Book list ──────────────────────────────────────────────────────────────

class _BookList extends ConsumerWidget {
  const _BookList({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = status == 'to_read'
        ? ref.watch(toReadBooksProvider)
        : ref.watch(readBooksProvider);

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading books')),
      data: (books) {
        if (books.isEmpty) {
          return _EmptyState(status: status);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: books.length,
          itemBuilder: (_, i) => _BookCard(book: books[i]),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isToRead = status == 'to_read';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isToRead
                    ? Icons.bookmark_add_outlined
                    : Icons.menu_book_rounded,
                color: AppColors.border,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isToRead ? 'No books in your list' : 'No books read yet',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              isToRead
                  ? 'Tap + to add books you want to read.'
                  : 'Mark books as read to see them here.',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book card ──────────────────────────────────────────────────────────────

class _BookCard extends ConsumerWidget {
  const _BookCard({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _genreColor(book.genre);
    final isRead = book.status == 'read';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Book cover placeholder
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.author!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (book.genre != null)
                          _Tag(label: book.genre!, color: color),
                        if (book.totalPages != null) ...[
                          const SizedBox(width: 6),
                          _Tag(
                            label: '${book.totalPages} pp',
                            color: AppColors.textMuted,
                          ),
                        ],
                      ],
                    ),
                    if (isRead && book.rating != null) ...[
                      const SizedBox(height: 6),
                      _StarRating(rating: book.rating!, color: color),
                    ],
                  ],
                ),
              ),

              // Action menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 18),
                color: AppColors.surface,
                onSelected: (v) => _onAction(v, ref, context),
                itemBuilder: (_) => [
                  if (!isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.green, size: 18),
                        SizedBox(width: 10),
                        Text('Mark as Read',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ]),
                    )
                  else
                    const PopupMenuItem(
                      value: 'mark_to_read',
                      child: Row(children: [
                        Icon(Icons.bookmark_outline_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 10),
                        Text('Move to To Read',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.red, size: 18),
                      SizedBox(width: 10),
                      Text('Delete',
                          style: TextStyle(color: AppColors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(
      String action, WidgetRef ref, BuildContext context) async {
    final repo = ref.read(booksRepositoryProvider);
    switch (action) {
      case 'mark_read':
        await repo.updateStatus(book.id, 'read');
        if (context.mounted) {
          _showRatingDialog(context, ref);
        }
      case 'mark_to_read':
        await repo.updateStatus(book.id, 'to_read');
      case 'delete':
        await repo.deleteBook(book.id);
    }
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        bookId: book.id,
        bookTitle: book.title,
        ref: ref,
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookDetailSheet(book: book, ref: ref),
    );
  }
}

// ── Book detail sheet ──────────────────────────────────────────────────────

class _BookDetailSheet extends StatelessWidget {
  const _BookDetailSheet({required this.book, required this.ref});
  final Book book;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final color = _genreColor(book.genre);
    final isRead = book.status == 'read';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 76,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
                    if (book.author != null) ...[
                      const SizedBox(height: 2),
                      Text(book.author!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (book.genre != null)
                          _Tag(label: book.genre!, color: color),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isRead ? AppColors.green : AppColors.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRead ? 'Read' : 'To Read',
                            style: TextStyle(
                              color: isRead ? AppColors.green : AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isRead && book.rating != null) ...[
            const SizedBox(height: 16),
            _StarRating(rating: book.rating!, color: color, size: 22),
          ],
          if (book.notes != null && book.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Notes',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(book.notes!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
          const SizedBox(height: 20),
          if (!isRead)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(booksRepositoryProvider)
                      .updateStatus(book.id, 'read');
                  if (context.mounted) {
                    _RatingDialog.show(context, ref, book.id, book.title);
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Mark as Read'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Rating dialog ──────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({
    required this.bookId,
    required this.bookTitle,
    required this.ref,
  });
  final int bookId;
  final String bookTitle;
  final WidgetRef ref;

  static void show(
      BuildContext context, WidgetRef ref, int bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (_) =>
          _RatingDialog(bookId: bookId, bookTitle: bookTitle, ref: ref),
    );
  }

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Rate this book',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.bookTitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= (_rating ?? 0)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: star <= (_rating ?? 0)
                        ? AppColors.amber
                        : AppColors.border,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        TextButton(
          onPressed: _rating == null
              ? null
              : () async {
                  await widget.ref
                      .read(booksRepositoryProvider)
                      .updateRating(widget.bookId, _rating);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Save',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ── Add book sheet ─────────────────────────────────────────────────────────

class _AddBookSheet extends StatefulWidget {
  const _AddBookSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<_AddBookSheet> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  String? _genre;
  String _status = 'to_read';
  int? _rating;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.ref.read(booksRepositoryProvider).addBook(
          title: _titleCtrl.text.trim(),
          author: _authorCtrl.text.trim().isEmpty
              ? null
              : _authorCtrl.text.trim(),
          genre: _genre,
          status: _status,
          rating: _status == 'read' ? _rating : null,
          totalPages: int.tryParse(_pagesCtrl.text.trim()),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Book',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            _label('Title'),
            _field(_titleCtrl, 'e.g. Atomic Habits', Icons.menu_book_rounded),
            const SizedBox(height: 14),

            _label('Author (optional)'),
            _field(_authorCtrl, 'e.g. James Clear', Icons.person_outline_rounded),
            const SizedBox(height: 14),

            _label('Genre (optional)'),
            DropdownButtonFormField<String>(
              value: _genre,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _dec('Select genre', Icons.label_outline_rounded),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ..._kGenres.map(
                    (g) => DropdownMenuItem(value: g, child: Text(g))),
              ],
              onChanged: (v) => setState(() => _genre = v),
            ),
            const SizedBox(height: 14),

            _label('Pages (optional)'),
            _field(_pagesCtrl, 'e.g. 320', Icons.format_list_numbered_rounded,
                keyboardType: TextInputType.number),
            const SizedBox(height: 14),

            _label('Status'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'To Read',
                    selected: _status == 'to_read',
                    onTap: () => setState(() => _status = 'to_read'),
                  ),
                  _StatusChip(
                    label: 'Read',
                    selected: _status == 'read',
                    onTap: () => setState(() => _status = 'read'),
                  ),
                ],
              ),
            ),

            if (_status == 'read') ...[
              const SizedBox(height: 14),
              _label('Rating (optional)'),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(
                        () => _rating = _rating == star ? null : star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        star <= (_rating ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: star <= (_rating ?? 0)
                            ? AppColors.amber
                            : AppColors.border,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving || _titleCtrl.text.trim().isEmpty
                    ? null
                    : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Book',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: _dec(hint, icon),
      );

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.color, this.size = 16});
  final int rating;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < rating ? AppColors.amber : AppColors.border,
          size: size,
        );
      }),
    );
  }
}
