import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../shared/widgets/main_scaffold.dart';
import '../providers/checklists_providers.dart';

class ChecklistsScreen extends ConsumerStatefulWidget {
  const ChecklistsScreen({super.key});

  @override
  ConsumerState<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

class _ChecklistsScreenState extends ConsumerState<ChecklistsScreen> {
  String _selectedFilter = 'all'; // all, my_lists, shared, archived
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checklistsRepositoryProvider).seedDefaults();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(checklistsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Lists',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () => _showAddSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search lists',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    ),
                ],
              ),
            ),
          ),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'My Lists',
                  isSelected: _selectedFilter == 'my_lists',
                  onTap: () => setState(() => _selectedFilter = 'my_lists'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Shared',
                  isSelected: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shared lists coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Lists display
          Expanded(
            child: listsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lists) {
                // Apply search and status filters
                final filteredLists = lists.where((list) {
                  final matchesSearch = list.name.toLowerCase().contains(_searchQuery);
                  final matchesFilter = _selectedFilter == 'all' || list.type == _selectedFilter;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredLists.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filteredLists.length,
                  itemBuilder: (context, idx) {
                    final list = filteredLists[idx];
                    return _ChecklistCard(
                      list: list,
                      onTap: () {
                        context.push(
                            '/lists/${list.id}?name=${Uri.encodeComponent(list.name)}');
                      },
                      onEdit: () => _showEditDialog(context, list),
                      onDelete: () => _confirmDelete(context, list),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddChecklistSheet(
        onAdd: (name, iconKey, type) async {
          await ref.read(checklistsRepositoryProvider).add(
                name: name,
                iconKey: iconKey,
                type: type,
              );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Checklist list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditChecklistSheet(
        list: list,
        onSave: (newName, newIconKey, newType) async {
          await ref.read(checklistsRepositoryProvider).updateName(list.id, newName);
          await ref.read(checklistsRepositoryProvider).updateIconAndType(list.id, newIconKey, newType);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Checklist list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete List', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
            'Are you sure you want to delete "${list.name}"? This will also delete all items in this list.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(checklistsRepositoryProvider).delete(list.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

IconData _getIconForList(String name, String? iconKey) {
  if (iconKey != null && iconKey.isNotEmpty) {
    switch (iconKey) {
      case 'work':
        return Icons.work_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'home':
        return Icons.home_rounded;
    }
  }
  final n = name.toLowerCase();
  if (n.contains('work') || n.contains('task')) return Icons.work_rounded;
  if (n.contains('grocery') || n.contains('shop') || n.contains('food')) {
    return Icons.shopping_cart_rounded;
  }
  if (n.contains('travel') || n.contains('pack') || n.contains('trip')) {
    return Icons.flight_takeoff_rounded;
  }
  if (n.contains('book') || n.contains('read')) return Icons.menu_book_rounded;
  if (n.contains('gift') || n.contains('present') || n.contains('idea')) {
    return Icons.card_giftcard_rounded;
  }
  if (n.contains('home') || n.contains('house') || n.contains('essential')) {
    return Icons.home_rounded;
  }
  return Icons.format_list_bulleted_rounded;
}

Color _getColorForList(String name, String? iconKey) {
  final icon = _getIconForList(name, iconKey);
  if (icon == Icons.work_rounded) return AppColors.primary;
  if (icon == Icons.shopping_cart_rounded) return AppColors.green;
  if (icon == Icons.flight_takeoff_rounded) return Colors.indigo;
  if (icon == Icons.menu_book_rounded) return AppColors.orange;
  if (icon == Icons.card_giftcard_rounded) return Colors.pink;
  if (icon == Icons.home_rounded) return Colors.blue;
  return AppColors.primary;
}

class _ChecklistCard extends ConsumerWidget {
  final Checklist list;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChecklistCard({
    required this.list,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsProvider(list.id));
    final icon = _getIconForList(list.name, list.iconKey);
    final color = _getColorForList(list.name, list.iconKey);

    final subtitleText = itemsAsync.when(
      data: (items) {
        final total = items.length;
        final remaining = items.where((i) => !i.isChecked).length;
        return '$total items • $remaining remaining';
      },
      loading: () => 'Loading items...',
      error: (_, __) => 'Error loading items',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppColors.textMuted, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
                    } else if (val == 'delete') {
                      onDelete();
                    }
                  },
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: AppColors.textPrimary, size: 18),
                          SizedBox(width: 8),
                          Text('Rename/Edit',
                              style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: AppColors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(Icons.format_list_bulleted_rounded,
                  color: AppColors.textMuted, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Lists Found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create lists for tasks, groceries, or travel, and filter them using the tabs above.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChecklistSheet extends StatefulWidget {
  final Future<void> Function(String name, String? iconKey, String type) onAdd;
  const _AddChecklistSheet({required this.onAdd});

  @override
  State<_AddChecklistSheet> createState() => _AddChecklistSheetState();
}

class _AddChecklistSheetState extends State<_AddChecklistSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;
  String _selectedIcon = 'default';
  String _selectedType = 'my_lists';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onAdd(
        text,
        _selectedIcon == 'default' ? null : _selectedIcon,
        _selectedType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
            const Text(
              'New List',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'List name (e.g. Work Tasks, Groceries)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter Category',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeRadio(
                  label: 'My Lists',
                  value: 'my_lists',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(width: 12),
                _TypeRadio(
                  label: 'Shared',
                  value: 'shared',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(width: 12),
                _TypeRadio(
                  label: 'Archived',
                  value: 'archived',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Icon',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IconButton(
                    icon: Icons.format_list_bulleted_rounded,
                    value: 'default',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'default')),
                _IconButton(
                    icon: Icons.work_rounded,
                    value: 'work',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'work')),
                _IconButton(
                    icon: Icons.shopping_cart_rounded,
                    value: 'shopping_cart',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'shopping_cart')),
                _IconButton(
                    icon: Icons.flight_takeoff_rounded,
                    value: 'flight',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'flight')),
                _IconButton(
                    icon: Icons.menu_book_rounded,
                    value: 'book',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'book')),
                _IconButton(
                    icon: Icons.card_giftcard_rounded,
                    value: 'gift',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'gift')),
                _IconButton(
                    icon: Icons.home_rounded,
                    value: 'home',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'home')),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create List',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditChecklistSheet extends StatefulWidget {
  final Checklist list;
  final Future<void> Function(String name, String? iconKey, String type) onSave;
  const _EditChecklistSheet({required this.list, required this.onSave});

  @override
  State<_EditChecklistSheet> createState() => _EditChecklistSheetState();
}

class _EditChecklistSheetState extends State<_EditChecklistSheet> {
  late final _ctrl = TextEditingController(text: widget.list.name);
  bool _saving = false;
  late String _selectedIcon = widget.list.iconKey ?? 'default';
  late String _selectedType = widget.list.type;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        text,
        _selectedIcon == 'default' ? null : _selectedIcon,
        _selectedType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
            const Text(
              'Edit List Details',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'List name',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter Category',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeRadio(
                  label: 'My Lists',
                  value: 'my_lists',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(width: 12),
                _TypeRadio(
                  label: 'Shared',
                  value: 'shared',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
                const SizedBox(width: 12),
                _TypeRadio(
                  label: 'Archived',
                  value: 'archived',
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Icon',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _IconButton(
                    icon: Icons.format_list_bulleted_rounded,
                    value: 'default',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'default')),
                _IconButton(
                    icon: Icons.work_rounded,
                    value: 'work',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'work')),
                _IconButton(
                    icon: Icons.shopping_cart_rounded,
                    value: 'shopping_cart',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'shopping_cart')),
                _IconButton(
                    icon: Icons.flight_takeoff_rounded,
                    value: 'flight',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'flight')),
                _IconButton(
                    icon: Icons.menu_book_rounded,
                    value: 'book',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'book')),
                _IconButton(
                    icon: Icons.card_giftcard_rounded,
                    value: 'gift',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'gift')),
                _IconButton(
                    icon: Icons.home_rounded,
                    value: 'home',
                    groupValue: _selectedIcon,
                    onTap: () => setState(() => _selectedIcon = 'home')),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRadio extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _TypeRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String value;
  final String groupValue;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
