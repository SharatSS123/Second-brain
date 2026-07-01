import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';

class EntertainmentListItem extends StatelessWidget {
  final EntertainmentItem item;
  final VoidCallback? onPrimaryAction; // mark watched / move to watchlist
  final VoidCallback? onDelete;
  final bool showRating;

  const EntertainmentListItem({
    super.key,
    required this.item,
    this.onPrimaryAction,
    this.onDelete,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForType(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            if (item.year != null) ...[
              Text(
                item.year.toString(),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (item.genre != null)
                Text(
                  ' · ',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
            if (item.genre != null)
              Flexible(
                child: Text(
                  item.genre!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRating && item.rating != null) ...[
              Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
              const SizedBox(width: 2),
              Text(
                item.rating.toString(),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(width: 8),
            ],
            if (onPrimaryAction != null)
              IconButton(
                tooltip: item.status == 'Watchlist' ? 'Mark as watched' : 'Move to watchlist',
                icon: Icon(
                  item.status == 'Watchlist'
                      ? Icons.check_circle_outline
                      : Icons.undo_rounded,
                  color: item.status == 'Watchlist'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onPrimaryAction,
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('"${item.title}" will be removed from your list.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Movie':
        return Colors.blue;
      case 'TV Series':
        return Colors.purple;
      case 'Anime':
        return Colors.orange;
      case 'Book':
        return Colors.green;
      case 'Game':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class EntertainmentEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EntertainmentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outlineVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
