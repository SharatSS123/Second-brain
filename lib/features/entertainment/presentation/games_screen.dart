import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entertainment_providers.dart';
import 'add_entertainment_sheet.dart';
import 'entertainment_list_item.dart';

const _gameGenres = [
  'Action', 'Adventure', 'Fighting', 'Horror',
  'Platformer', 'Puzzle', 'Racing', 'RPG',
  'Shooter', 'Simulation', 'Sports', 'Strategy',
];

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen>
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
        title: const Text('Games'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Backlog'),
            Tab(text: 'Played'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GamesBacklogTab(),
          _GamesPlayedTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Game'),
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
        type: 'Game',
        customGenres: _gameGenres,
        addLabel: 'Add to Backlog',
      ),
    );
  }
}

class _GamesBacklogTab extends ConsumerWidget {
  const _GamesBacklogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gamesBacklogProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.sports_esports_outlined,
            title: 'Your backlog is empty',
            subtitle: 'Tap "Add Game" to save games you want to play',
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

class _GamesPlayedTab extends ConsumerWidget {
  const _GamesPlayedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playedGamesProvider);
    final repo = ref.read(entertainmentRepositoryProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return const EntertainmentEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No played games yet',
            subtitle: 'Games you finish will appear here',
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
