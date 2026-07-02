import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/tables/planner_table.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';

class EditTemplateScreen extends ConsumerStatefulWidget {
  const EditTemplateScreen({super.key, required this.routine});
  final Routine routine;

  @override
  ConsumerState<EditTemplateScreen> createState() =>
      _EditTemplateScreenState();
}

class _EditTemplateScreenState extends ConsumerState<EditTemplateScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _schedule;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.routine.name);
    _descCtrl = TextEditingController(
        text: widget.routine.description ?? '');
    _schedule = widget.routine.schedule;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(plannerRepositoryProvider).updateRoutine(
          widget.routine.id,
          name: _nameCtrl.text.trim(),
          schedule: _schedule,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync =
        ref.watch(routineBlocksProvider(widget.routine.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Template',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Template name
          const Text('Template Name',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('e.g. Workday', null),
          ),
          const SizedBox(height: 20),

          // Repeat
          const Text('Repeat',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  _schedLabel(_schedule),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showDayPicker(context),
                  child: const Text('Change days',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Description
          const Text('Description (optional)',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Add a short description...', null),
          ),
          const SizedBox(height: 28),

          // Activities section
          Row(
            children: [
              const Text('Activities',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),

          blocksAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (blocks) {
              if (blocks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No activities yet. Add one below.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: blocks.length,
                onReorder: (oldIdx, newIdx) async {
                  if (newIdx > oldIdx) newIdx--;
                  final reordered = [...blocks];
                  final item = reordered.removeAt(oldIdx);
                  reordered.insert(newIdx, item);
                  for (int i = 0; i < reordered.length; i++) {
                    await ref
                        .read(plannerRepositoryProvider)
                        .updateRoutineBlockOrder(reordered[i].id, i);
                  }
                },
                itemBuilder: (ctx, i) => _EditableBlockRow(
                  key: ValueKey(blocks[i].id),
                  block: blocks[i],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Add activity link
          GestureDetector(
            onTap: () => _showAddBlockDialog(context),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border, width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 6),
                  Text('+ Add Activity',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showDayPicker(BuildContext context) async {
    final options = ['any', 'weekdays', 'weekends'];
    final labels = ['Any day', 'Mon – Fri', 'Sat – Sun'];
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Repeat',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            options.length,
            (i) => RadioListTile<String>(
              value: options[i],
              groupValue: _schedule,
              title: Text(labels[i],
                  style:
                      const TextStyle(color: AppColors.textPrimary)),
              activeColor: AppColors.primary,
              onChanged: (v) {
                setState(() => _schedule = v!);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddBlockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBlockToTemplateSheet(
        routineId: widget.routine.id,
        ref: ref,
        existingCount: ref
                .read(routineBlocksProvider(widget.routine.id))
                .value
                ?.length ??
            0,
      ),
    );
  }

  InputDecoration _dec(String hint, IconData? icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.textMuted, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  String _schedLabel(String s) => switch (s) {
        'weekdays' => 'Mon – Fri',
        'weekends' => 'Sat – Sun',
        _ => 'Any day',
      };
}

class _EditableBlockRow extends ConsumerWidget {
  const _EditableBlockRow({super.key, required this.block});
  final RoutineBlock block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = categoryStyle(block.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle_rounded,
              color: AppColors.border, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(displayTime(block.startTime),
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(block.title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textMuted, size: 18),
            onPressed: () => _showOptions(context, ref),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.red),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.red)),
              onTap: () async {
                await ref
                    .read(plannerRepositoryProvider)
                    .deleteRoutineBlock(block.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add block to template sheet ────────────────────────────────────────────

class _AddBlockToTemplateSheet extends StatefulWidget {
  const _AddBlockToTemplateSheet({
    required this.routineId,
    required this.ref,
    required this.existingCount,
  });
  final String routineId;
  final WidgetRef ref;
  final int existingCount;

  @override
  State<_AddBlockToTemplateSheet> createState() =>
      _AddBlockToTemplateSheetState();
}

class _AddBlockToTemplateSheetState
    extends State<_AddBlockToTemplateSheet> {
  final _titleCtrl = TextEditingController(text: 'New Activity');
  final _notesCtrl = TextEditingController();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 60;
  String _category = 'Work';
  bool _allDay = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.ref.read(plannerRepositoryProvider).addRoutineBlock(
          routineId: widget.routineId,
          title: _titleCtrl.text.trim(),
          startTime: _allDay ? '00:00' : timeStr(_start),
          durationMinutes: _allDay ? 1440 : _durationMinutes,
          category: _category,
          sortOrder: widget.existingCount,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final endH = (_start.hour * 60 + _start.minute + _durationMinutes) ~/ 60;
    final endM = (_start.hour * 60 + _start.minute + _durationMinutes) % 60;
    final endTod = TimeOfDay(hour: endH % 24, minute: endM);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const Spacer(),
              const Text('Add Activity',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : _add,
                child: const Text('Done',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Activity type chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_box_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Text('Task',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Routines can only contain tasks.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          _label('Title'),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec(null),
          ),
          const SizedBox(height: 12),
          _label('Time'),
          Row(
            children: [
              if (!_allDay) ...[
                Expanded(child: _timeTile(_start, (t) => setState(() => _start = t), context)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                Expanded(child: _timeTile(endTod, (t) {
                  final diffMins = (t.hour * 60 + t.minute) -
                      (_start.hour * 60 + _start.minute);
                  if (diffMins > 0) setState(() => _durationMinutes = diffMins);
                }, context)),
                const SizedBox(width: 8),
              ] else
                const Expanded(child: SizedBox()),
              const Text('All day',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 4),
              Switch(
                value: _allDay,
                onChanged: (v) => setState(() => _allDay = v),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _label('Category'),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec(null),
            items: kCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          _label('Notes (optional)'),
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Add notes...'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Add to Template',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
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

  Widget _timeTile(TimeOfDay tod, ValueChanged<TimeOfDay> onChanged,
      BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: tod,
          builder: (ctx, child) =>
              Theme(data: ThemeData.dark(), child: child!),
        );
        if (t != null) onChanged(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(tod.format(context),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
