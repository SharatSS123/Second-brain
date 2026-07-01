import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../providers/entertainment_providers.dart';
import 'add_entertainment_sheet.dart';
import 'entertainment_list_item.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Watched'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WatchlistTab(),
          _WatchedTab(),
          _TrendingTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Movie'),
            )
          : null,
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddEntertainmentSheet(type: 'Movie'),
    );
  }
}

// ── Watchlist Tab ──────────────────────────────────────────────────────────────

class _WatchlistTab extends ConsumerWidget {
  const _WatchlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(movieWatchlistProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.movie_outlined,
            title: 'Your watchlist is empty',
            subtitle: 'Tap "Add Movie" to save movies you want to watch',
          );
        }
        return _MovieList(
          items: items,
          onPrimaryAction: (item) => repo.markAsWatched(item.id),
          onDelete: (item) => repo.delete(item.id),
        );
      },
    );
  }
}

// ── Watched Tab ────────────────────────────────────────────────────────────────

class _WatchedTab extends ConsumerWidget {
  const _WatchedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchedMoviesProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No watched movies yet',
            subtitle: 'Movies you mark as watched will appear here',
          );
        }
        return _MovieList(
          items: items,
          showRating: true,
          onPrimaryAction: (item) => repo.moveToWatchlist(item.id),
          onDelete: (item) => repo.delete(item.id),
          onRatingTap: (item) => _showRatingDialog(context, ref, item),
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, EntertainmentItem item) {
    showDialog(
      context: context,
      builder: (ctx) => _RatingDialog(
        item: item,
        onRate: (rating) {
          ref.read(entertainmentRepositoryProvider).updateRating(item.id, rating);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ── Trending Tab ───────────────────────────────────────────────────────────────

class _TrendingTab extends StatelessWidget {
  const _TrendingTab();

  @override
  Widget build(BuildContext context) {
    return const EntertainmentEmptyState(
      icon: Icons.trending_up_rounded,
      title: 'Trending coming soon',
      subtitle: 'We\'ll show popular movies here once online data is connected',
    );
  }
}

// ── Shared list widget ─────────────────────────────────────────────────────────

class _MovieList extends StatelessWidget {
  final List<EntertainmentItem> items;
  final Future<void> Function(EntertainmentItem) onPrimaryAction;
  final Future<void> Function(EntertainmentItem) onDelete;
  final void Function(EntertainmentItem)? onRatingTap;
  final bool showRating;

  const _MovieList({
    required this.items,
    required this.onPrimaryAction,
    required this.onDelete,
    this.onRatingTap,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(indent: 72, height: 0),
      itemBuilder: (context, i) {
        final item = items[i];
        return EntertainmentListItem(
          item: item,
          showRating: showRating,
          onPrimaryAction: () => onPrimaryAction(item),
          onDelete: () => onDelete(item),
        );
      },
    );
  }
}

// ── Rating Dialog ──────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final EntertainmentItem item;
  final void Function(int) onRate;

  const _RatingDialog({required this.item, required this.onRate});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.item.rating ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate "${widget.item.title}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_rating / 10', style: Theme.of(context).textTheme.displaySmall),
          Slider(
            value: _rating.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_rating',
            onChanged: (v) => setState(() => _rating = v.round()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => widget.onRate(_rating), child: const Text('Save')),
      ],
    );
  }
}
