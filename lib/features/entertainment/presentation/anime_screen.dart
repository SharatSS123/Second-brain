import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entertainment_providers.dart';
import 'add_entertainment_sheet.dart';
import 'entertainment_list_item.dart';

const _animeGenres = [
  'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy',
  'Horror', 'Isekai', 'Mecha', 'Romance', 'Sci-Fi',
  'Seinen', 'Shonen', 'Slice of Life', 'Supernatural',
];

class AnimeScreen extends ConsumerStatefulWidget {
  const AnimeScreen({super.key});

  @override
  ConsumerState<AnimeScreen> createState() => _AnimeScreenState();
}

class _AnimeScreenState extends ConsumerState<AnimeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Anime'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Watched'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AnimeWatchlistTab(),
          _AnimeWatchedTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Anime'),
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
      builder: (_) => const AddEntertainmentSheet(
        type: 'Anime',
        customGenres: _animeGenres,
      ),
    );
  }
}

class _AnimeWatchlistTab extends ConsumerWidget {
  const _AnimeWatchlistTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(animeWatchlistProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.animation_outlined,
            title: 'Your watchlist is empty',
            subtitle: 'Tap "Add Anime" to save shows you want to watch',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(indent: 72, height: 0),
          itemBuilder: (context, i) {
            final item = items[i];
            return EntertainmentListItem(
              item: item,
              onPrimaryAction: () => repo.markAsWatched(item.id),
              onDelete: () => repo.delete(item.id),
            );
          },
        );
      },
    );
  }
}

class _AnimeWatchedTab extends ConsumerWidget {
  const _AnimeWatchedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(watchedAnimeProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No watched anime yet',
            subtitle: 'Anime you finish will appear here',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(indent: 72, height: 0),
          itemBuilder: (context, i) {
            final item = items[i];
            return EntertainmentListItem(
              item: item,
              showRating: true,
              onPrimaryAction: () => repo.moveToWatchlist(item.id),
              onDelete: () => repo.delete(item.id),
            );
          },
        );
      },
    );
  }
}
