import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EntertainmentScreen extends StatelessWidget {
  const EntertainmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entertainment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What are you into?',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _CategoryCard(
                    title: 'Movies',
                    subtitle: 'Track your watchlist',
                    icon: Icons.movie_rounded,
                    color: Colors.blue,
                    onTap: () => context.push('/entertainment/movies'),
                  ),
                  _CategoryCard(
                    title: 'TV Series',
                    subtitle: 'Episodes & seasons',
                    icon: Icons.tv_rounded,
                    color: Colors.purple,
                    onTap: () => context.push('/entertainment/series'),
                  ),
                  _CategoryCard(
                    title: 'Anime',
                    subtitle: 'Coming soon',
                    icon: Icons.animation_rounded,
                    color: Colors.orange,
                    onTap: null,
                    comingSoon: true,
                  ),
                  _CategoryCard(
                    title: 'Books',
                    subtitle: 'Coming soon',
                    icon: Icons.menu_book_rounded,
                    color: Colors.green,
                    onTap: null,
                    comingSoon: true,
                  ),
                  _CategoryCard(
                    title: 'Games',
                    subtitle: 'Coming soon',
                    icon: Icons.sports_esports_rounded,
                    color: Colors.red,
                    onTap: null,
                    comingSoon: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (comingSoon) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Soon',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
