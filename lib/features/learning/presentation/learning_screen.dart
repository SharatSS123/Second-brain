import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/learning_providers.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Learning Hub',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search coming soon'), behavior: SnackBarBehavior.floating),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Topics'), Tab(text: 'Resources')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_TopicsTab(), _ResourcesTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTopicDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddTopicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddTopicDialog(
        onAdd: (name, color) async {
          await ref.read(learningRepositoryProvider).addTopic(
                name: name,
                color: color,
              );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

// ── Topics Tab ────────────────────────────────────────────────────────────────

class _TopicsTab extends ConsumerWidget {
  const _TopicsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(learningTopicsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (topics) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: topics.length + 1, // +1 for Add card
        itemBuilder: (context, i) {
          if (i == topics.length) {
            return _AddTopicCard(
              onTap: () => _showAddTopicDialogFromContext(context, ref),
            );
          }
          return _TopicCard(
            topic: topics[i],
            colorIndex: i,
            onTap: () => _openTopic(context, topics[i]),
            onDelete: () =>
                ref.read(learningRepositoryProvider).deleteTopic(topics[i].id),
            onProgressUpdate: (p) => ref
                .read(learningRepositoryProvider)
                .updateTopicProgress(topics[i].id, p),
          );
        },
      ),
    );
  }

  void _showAddTopicDialogFromContext(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddTopicDialog(
        onAdd: (name, color) async {
          await ref.read(learningRepositoryProvider).addTopic(name: name, color: color);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openTopic(BuildContext context, LearningTopicsTableData topic) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _TopicDetailScreen(topic: topic)),
    );
  }
}

// ── Topic Card ────────────────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final LearningTopicsTableData topic;
  final int colorIndex;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressUpdate;

  const _TopicCard({
    required this.topic,
    required this.colorIndex,
    required this.onTap,
    required this.onDelete,
    required this.onProgressUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor();
    final progress = topic.progressPercent / 100;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showOptions(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_rounded, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                topic.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${topic.progressPercent}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  color: color,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _resolveColor() {
    if (topic.color != null) {
      try {
        return Color(int.parse(topic.color!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppColors.topicColor(colorIndex);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _TopicOptionsSheet(
        topic: topic,
        onDelete: onDelete,
        onProgressUpdate: onProgressUpdate,
      ),
    );
  }
}

class _TopicOptionsSheet extends StatefulWidget {
  final LearningTopicsTableData topic;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressUpdate;

  const _TopicOptionsSheet(
      {required this.topic, required this.onDelete, required this.onProgressUpdate});

  @override
  State<_TopicOptionsSheet> createState() => _TopicOptionsSheetState();
}

class _TopicOptionsSheetState extends State<_TopicOptionsSheet> {
  late double _progress;

  @override
  void initState() {
    super.initState();
    _progress = widget.topic.progressPercent.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.topic.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Progress: ${_progress.round()}%',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Slider(
            value: _progress,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (v) => setState(() => _progress = v),
            onChangeEnd: (v) => widget.onProgressUpdate(v.round()),
          ),
          const Divider(color: AppColors.divider),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.red),
            title: const Text('Delete topic',
                style: TextStyle(color: AppColors.red)),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _AddTopicCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTopicCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          color: AppColors.card.withValues(alpha: 0.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 32),
            SizedBox(height: 8),
            Text('Add Topic',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Topic Detail Screen ───────────────────────────────────────────────────────

class _TopicDetailScreen extends ConsumerWidget {
  final LearningTopicsTableData topic;
  const _TopicDetailScreen({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(learningResourcesProvider(topic.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(topic.name)),
      body: resourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (resources) {
          if (resources.isEmpty) {
            return const Center(
              child: Text('No resources yet.\nTap + to add.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: resources.length,
            itemBuilder: (context, i) {
              final r = resources[i];
              return _ResourceTile(
                resource: r,
                onToggle: () => ref
                    .read(learningRepositoryProvider)
                    .toggleResourceComplete(r.id, !r.isCompleted),
                onDelete: () =>
                    ref.read(learningRepositoryProvider).deleteResource(r.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddResource(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddResource(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddResourceDialog(
        onAdd: (title, type, url) async {
          await ref.read(learningRepositoryProvider).addResource(
                topicId: topic.id,
                title: title,
                type: type,
                url: url.isNotEmpty ? url : null,
              );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final LearningResourcesTableData resource;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ResourceTile(
      {required this.resource, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_typeIcon(resource.type), color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: TextStyle(
                    color: resource.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    decoration: resource.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  resource.type,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              resource.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: resource.isCompleted ? AppColors.green : AppColors.textMuted,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textMuted, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Video': return Icons.play_circle_outline;
      case 'Article': return Icons.article_outlined;
      case 'Book': return Icons.menu_book_outlined;
      case 'Podcast': return Icons.podcasts_outlined;
      default: return Icons.school_outlined;
    }
  }
}

// ── Resources Tab ─────────────────────────────────────────────────────────────

class _ResourcesTab extends ConsumerWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(learningTopicsProvider);
    return topicsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (topics) => topics.isEmpty
          ? const Center(
              child: Text('Add topics first to see resources.',
                  style: TextStyle(color: AppColors.textSecondary)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: topics
                  .map((t) => _TopicResourceSection(topic: t))
                  .toList(),
            ),
    );
  }
}

class _TopicResourceSection extends ConsumerWidget {
  final LearningTopicsTableData topic;
  const _TopicResourceSection({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(learningResourcesProvider(topic.id));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (resources) {
        if (resources.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                topic.name,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
            ...resources.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ResourceTile(
                    resource: r,
                    onToggle: () => ref
                        .read(learningRepositoryProvider)
                        .toggleResourceComplete(r.id, !r.isCompleted),
                    onDelete: () =>
                        ref.read(learningRepositoryProvider).deleteResource(r.id),
                  ),
                )),
          ],
        );
      },
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

class _AddTopicDialog extends StatefulWidget {
  final Future<void> Function(String name, String? color) onAdd;
  const _AddTopicDialog({required this.onAdd});

  @override
  State<_AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<_AddTopicDialog> {
  final _controller = TextEditingController();
  Color _selectedColor = AppColors.primary;
  bool _isSaving = false;

  static const _colors = [
    AppColors.green, AppColors.amber, AppColors.primary,
    AppColors.blue, AppColors.orange, AppColors.teal, AppColors.pink,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('New Topic',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Topic name (e.g. Flutter)'),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Color', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _colors.map((c) {
              final selected = c == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSaving || _controller.text.trim().isEmpty
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  final hex =
                      '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
                  await widget.onAdd(_controller.text.trim(), hex);
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _AddResourceDialog extends StatefulWidget {
  final Future<void> Function(String title, String type, String url) onAdd;
  const _AddResourceDialog({required this.onAdd});

  @override
  State<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<_AddResourceDialog> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String _type = 'Course';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Resource',
          style: TextStyle(color: AppColors.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Resource title *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['Course', 'Article', 'Video', 'Book', 'Podcast']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'URL (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSaving ? null : () async {
            if (_titleController.text.trim().isEmpty) return;
            setState(() => _isSaving = true);
            await widget.onAdd(
                _titleController.text.trim(), _type, _urlController.text.trim());
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
