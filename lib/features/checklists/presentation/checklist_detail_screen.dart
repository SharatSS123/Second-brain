import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../providers/checklists_providers.dart';

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  final String checklistId;
  final String checklistName;

  const ChecklistDetailScreen({
    super.key,
    required this.checklistId,
    required this.checklistName,
  });

  @override
  ConsumerState<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addItem() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    try {
      await ref.read(checklistsRepositoryProvider).addItem(
            checklistId: widget.checklistId,
            title: text,
          );
      // Scroll to top to show new item
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _showEditItemSheet(ChecklistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(
        item: item,
        onSave: ({
          required String title,
          String? notes,
          String? priority,
          DateTime? dueDate,
        }) async {
          await ref.read(checklistsRepositoryProvider).updateItem(
                id: item.id,
                title: title,
                notes: notes,
                priority: priority,
                dueDate: dueDate,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(checklistItemsProvider(widget.checklistId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          widget.checklistName,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final completedCount = items.where((i) => i.isChecked).length;

          return Column(
            children: [
              // Quick Add at the top
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _inputCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a new item...',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      onPressed: _addItem,
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      heroTag: 'checklist_quick_add',
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: items.isEmpty
                    ? const _EmptyItemsState()
                    : ReorderableListView.builder(
                        scrollController: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return _ItemTile(
                            key: ValueKey(item.id),
                            item: item,
                            index: idx,
                            onToggle: () => ref
                                .read(checklistsRepositoryProvider)
                                .toggleItem(item.id, item.isChecked),
                            onEdit: () => _showEditItemSheet(item),
                            onDelete: () => ref
                                .read(checklistsRepositoryProvider)
                                .deleteItem(item.id),
                            onMoveToTop: () => ref
                                .read(checklistsRepositoryProvider)
                                .moveItemToTop(widget.checklistId, item.id),
                            onMoveToBottom: () => ref
                                .read(checklistsRepositoryProvider)
                                .moveItemToBottom(widget.checklistId, item.id),
                          );
                        },
                        onReorder: (oldIdx, newIdx) async {
                          if (newIdx > oldIdx) {
                            newIdx -= 1;
                          }
                          final updatedList = [...items];
                          final moved = updatedList.removeAt(oldIdx);
                          updatedList.insert(newIdx, moved);
                          await ref
                              .read(checklistsRepositoryProvider)
                              .updateItemsOrder(updatedList);
                        },
                        buildDefaultDragHandles: false,
                      ),
              ),

              // Footer counters and clear completed
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of ${items.length} completed',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (completedCount > 0)
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(checklistsRepositoryProvider)
                              .clearCompleted(widget.checklistId);
                        },
                        child: const Text(
                          'Clear completed',
                          style: TextStyle(
                            color: AppColors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ChecklistItem item;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveToTop;
  final VoidCallback onMoveToBottom;

  const _ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveToTop,
    required this.onMoveToBottom,
  });

  @override
  Widget build(BuildContext context) {
    Color? priorityColor;
    if (item.priority != null) {
      if (item.priority == 'low') priorityColor = AppColors.green;
      if (item.priority == 'medium') priorityColor = AppColors.orange;
      if (item.priority == 'high') priorityColor = AppColors.red;
    }

    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.textMuted, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Notes, Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.isChecked ? AppColors.textMuted : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w500,
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (priorityColor != null || item.dueDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (priorityColor != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: priorityColor, width: 0.5),
                              ),
                              child: Text(
                                item.priority!.toUpperCase(),
                                style: TextStyle(
                                  color: priorityColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (item.dueDate != null) ...[
                            const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(item.dueDate!),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Options Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    onEdit();
                  } else if (val == 'toggle') {
                    onToggle();
                  } else if (val == 'top') {
                    onMoveToTop();
                  } else if (val == 'bottom') {
                    onMoveToBottom();
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, color: AppColors.textPrimary, size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          item.isChecked
                              ? Icons.radio_button_unchecked_rounded
                              : Icons.check_circle_outline_rounded,
                          color: AppColors.textPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.isChecked ? 'Mark as incomplete' : 'Mark as done',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'top',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, color: AppColors.textPrimary, size: 18),
                        SizedBox(width: 8),
                        Text('Move to top', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'bottom',
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, color: AppColors.textPrimary, size: 18),
                        SizedBox(width: 8),
                        Text('Move to bottom', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.red)),
                      ],
                    ),
                  ),
                ],
              ),

              // Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.drag_handle_rounded, color: AppColors.textMuted, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No items yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Type above and press the plus button to add items to this checklist.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemSheet extends StatefulWidget {
  final ChecklistItem item;
  final Future<void> Function({
    required String title,
    String? notes,
    String? priority,
    DateTime? dueDate,
  }) onSave;

  const _EditItemSheet({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final _titleCtrl = TextEditingController(text: widget.item.title);
  late final _notesCtrl = TextEditingController(text: widget.item.notes);
  late String? _selectedPriority = widget.item.priority;
  late DateTime? _selectedDueDate = widget.item.dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        title: title,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Item',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Item title',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                  onPressed: () => _titleCtrl.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Priority',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _PriorityRadio(
                  label: 'Low',
                  value: 'low',
                  color: AppColors.green,
                  groupValue: _selectedPriority,
                  onChanged: (val) => setState(() => _selectedPriority = val),
                ),
                const SizedBox(width: 12),
                _PriorityRadio(
                  label: 'Medium',
                  value: 'medium',
                  color: AppColors.orange,
                  groupValue: _selectedPriority,
                  onChanged: (val) => setState(() => _selectedPriority = val),
                ),
                const SizedBox(width: 12),
                _PriorityRadio(
                  label: 'High',
                  value: 'high',
                  color: AppColors.red,
                  groupValue: _selectedPriority,
                  onChanged: (val) => setState(() => _selectedPriority = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Due Date',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _selectedDueDate == null
                          ? 'Select date'
                          : DateFormat('MMMM d, yyyy').format(_selectedDueDate!),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border, width: 0.5),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (_selectedDueDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.red),
                    onPressed: () => setState(() => _selectedDueDate = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.border, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityRadio extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _PriorityRadio({
    required this.label,
    required this.value,
    required this.color,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(isSelected ? null : value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
