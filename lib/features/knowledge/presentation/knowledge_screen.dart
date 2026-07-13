import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/knowledge_providers.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Links', 'Docs', 'Images', 'Videos', 'Audio'];
  static const _filterTypeMap = {
    'Links': 'Link',
    'Docs': 'Note',
    'Images': 'Image',
    'Videos': 'Video',
    'Audio': 'Audio',
  };

  @override
  Widget build(BuildContext context) {
    final type = _filterTypeMap[_filter];
    final async = type == null
        ? ref.watch(allKnowledgeProvider)
        : ref.watch(knowledgeByTypeProvider(type));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Vault',
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type filter icons row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _filters.map((f) {
                final selected = _filter == f;
                return _FilterIcon(
                  label: f,
                  icon: _filterIcon(f),
                  selected: selected,
                  onTap: () => setState(() => _filter = f),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 0),

          // Items list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'All Items',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) => items.isEmpty
                  ? const _EmptyVault()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: items.length,
                      itemBuilder: (context, i) => _VaultItem(
                        item: items[i],
                        onToggleFavorite: () => ref
                            .read(knowledgeRepositoryProvider)
                            .toggleFavorite(items[i].id, !items[i].isFavorite),
                        onDelete: () =>
                            ref.read(knowledgeRepositoryProvider).delete(items[i].id),
                        onTap: () => _showDetailsSheet(context, items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  IconData _filterIcon(String f) {
    switch (f) {
      case 'All': return Icons.grid_view_rounded;
      case 'Links': return Icons.link_rounded;
      case 'Docs': return Icons.description_outlined;
      case 'Images': return Icons.image_outlined;
      case 'Videos': return Icons.play_circle_outline;
      case 'Audio': return Icons.music_note_outlined;
      default: return Icons.folder_outlined;
    }
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddVaultSheet(
        onAdd: (title, type, content, source) async {
          await ref.read(knowledgeRepositoryProvider).add(
                title: title,
                type: type,
                content: content.isNotEmpty ? content : null,
                source: source.isNotEmpty ? source : null,
              );
        },
      ),
    );
  }
}

// ── Filter Icon Button ────────────────────────────────────────────────────────

class _FilterIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterIcon({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textMuted,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vault Item ────────────────────────────────────────────────────────────────

class _VaultItem extends StatelessWidget {
  final KnowledgeTableData item;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _VaultItem({
    required this.item,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(item.type);
    final typeIcon = _typeIcon(item.type);
    final timeAgo = _formatDate(item.createdAt);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.type}  ·  $timeAgo',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: Icon(
                    item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: item.isFavorite ? AppColors.amber : AppColors.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Link': return AppColors.blue;
      case 'Note': return AppColors.amber;
      case 'Code': return AppColors.green;
      case 'Idea': return AppColors.primary;
      case 'Image': return AppColors.pink;
      case 'Video': return AppColors.red;
      case 'Audio': return AppColors.teal;
      default: return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Link': return Icons.link_rounded;
      case 'Note': return Icons.description_outlined;
      case 'Code': return Icons.code_rounded;
      case 'Idea': return Icons.lightbulb_outline;
      case 'Image': return Icons.image_outlined;
      case 'Video': return Icons.play_circle_outline;
      case 'Audio': return Icons.music_note_outlined;
      default: return Icons.folder_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 72, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text('Your vault is empty',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Save links, notes, ideas & more',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Add Sheet ─────────────────────────────────────────────────────────────────

class _AddVaultSheet extends StatefulWidget {
  final Future<void> Function(String title, String type, String content, String source) onAdd;
  const _AddVaultSheet({required this.onAdd});

  @override
  State<_AddVaultSheet> createState() => _AddVaultSheetState();
}

class _AddVaultSheetState extends State<_AddVaultSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _sourceController = TextEditingController();
  String _type = 'Link';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Save to Vault',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Title *'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Type'),
            items: ['Link', 'Note', 'Code', 'Idea', 'Image']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: _type == 'Link' ? 'URL or paste link' : 'Content',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sourceController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Source (optional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving || _titleController.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      await widget.onAdd(
                        _titleController.text.trim(),
                        _type,
                        _contentController.text.trim(),
                        _sourceController.text.trim(),
                      );
                      if (mounted) Navigator.of(context).pop();
                    },
              child: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details Sheet ─────────────────────────────────────────────────────────────

void _showDetailsSheet(BuildContext context, KnowledgeTableData item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _VaultItemDetailsSheet(item: item),
  );
}

class _VaultItemDetailsSheet extends StatelessWidget {
  final KnowledgeTableData item;
  const _VaultItemDetailsSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(item.type);
    final typeIcon = _typeIcon(item.type);
    final hasContent = item.content != null && item.content!.trim().isNotEmpty;
    final hasSource = item.source != null && item.source!.trim().isNotEmpty;
    final isLink = item.type == 'Link' && hasContent;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      item.type,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy  •  h:mm a').format(item.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (hasContent) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: SelectableText(
                item.content!,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.5,
                  fontFamily: item.type == 'Code' ? 'monospace' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (hasSource) ...[
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Source: ${item.source}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              if (hasContent) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.content!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (isLink) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _launchURL(context, item.content!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open Link', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.border,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Link': return AppColors.blue;
      case 'Note': return AppColors.amber;
      case 'Code': return AppColors.green;
      case 'Idea': return AppColors.primary;
      case 'Image': return AppColors.pink;
      case 'Video': return AppColors.red;
      case 'Audio': return AppColors.teal;
      default: return AppColors.textMuted;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Link': return Icons.link_rounded;
      case 'Note': return Icons.description_outlined;
      case 'Code': return Icons.code_rounded;
      case 'Idea': return Icons.lightbulb_outline;
      case 'Image': return Icons.image_outlined;
      case 'Video': return Icons.play_circle_outline;
      case 'Audio': return Icons.music_note_outlined;
      default: return Icons.folder_outlined;
    }
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString.trim());
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $urlString';
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening link: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
