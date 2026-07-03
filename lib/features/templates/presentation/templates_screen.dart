import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';
import 'template_detail_screen.dart';

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Templates',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showCreateSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tc,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'My Templates'),
                  Tab(text: 'Recommended'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _MyTemplates(),
          _RecommendedTemplates(),
        ],
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateTemplateSheet(ref: ref),
    );
  }
}

class _MyTemplates extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    return routinesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error')),
      data: (routines) {
        if (routines.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.grid_view_rounded,
                      color: AppColors.border, size: 48),
                  const SizedBox(height: 12),
                  const Text('No templates yet',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text(
                    'Create templates to quickly populate\nyour daily timeline.',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: routines.length,
          itemBuilder: (_, i) => _TemplateCard(routine: routines[i]),
        );
      },
    );
  }
}

// ── Recommended template data ──────────────────────────────────────────────

class _BlockDef {
  final String title;
  final String startTime;
  final int durationMinutes;
  final String category;
  const _BlockDef(this.title, this.startTime, this.durationMinutes, this.category);
}

class _RecommendedTemplate {
  final String name;
  final String category;
  final String schedule;
  final String description;
  final List<_BlockDef> blocks;
  const _RecommendedTemplate({
    required this.name,
    required this.category,
    required this.schedule,
    required this.description,
    required this.blocks,
  });
}

const _recommended = [
  _RecommendedTemplate(
    name: 'Productive Day',
    category: 'Work',
    schedule: 'weekdays',
    description: 'A structured Mon–Fri template balancing deep work and essential breaks.',
    blocks: [
      _BlockDef('Morning Routine',      '06:30', 30,  'Personal'),
      _BlockDef('Exercise',             '07:00', 30,  'Exercise'),
      _BlockDef('Breakfast',            '07:30', 30,  'Meals'),
      _BlockDef('Deep Focus Block 1',   '08:00', 90,  'Work'),
      _BlockDef('Email & Messages',     '09:30', 30,  'Work'),
      _BlockDef('Team Standup',         '10:00', 30,  'Meeting'),
      _BlockDef('Project Work',         '10:30', 90,  'Work'),
      _BlockDef('Lunch Break',          '12:00', 60,  'Meals'),
      _BlockDef('Deep Focus Block 2',   '13:00', 90,  'Work'),
      _BlockDef('Review & Follow-ups',  '14:30', 30,  'Work'),
      _BlockDef('Wind Down',            '17:00', 30,  'Personal'),
    ],
  ),
  _RecommendedTemplate(
    name: 'Weekend Relax',
    category: 'Leisure',
    schedule: 'weekends',
    description: 'A slow, restorative weekend — no rushing, just recharging.',
    blocks: [
      _BlockDef('Slow Morning',         '08:30', 60,  'Personal'),
      _BlockDef('Breakfast & Coffee',   '09:30', 45,  'Meals'),
      _BlockDef('Walk / Light Exercise','10:30', 45,  'Exercise'),
      _BlockDef('Lunch',                '12:30', 60,  'Meals'),
      _BlockDef('Rest & Recharge',      '14:00', 90,  'Personal'),
      _BlockDef('Hobbies & Leisure',    '16:00', 90,  'Leisure'),
      _BlockDef('Dinner',               '19:00', 60,  'Meals'),
      _BlockDef('Evening Wind Down',    '20:30', 45,  'Leisure'),
    ],
  ),
  _RecommendedTemplate(
    name: 'Deep Work',
    category: 'Work',
    schedule: 'any',
    description: 'Three uninterrupted 90-min focus blocks. No meetings, no distractions.',
    blocks: [
      _BlockDef('Morning Prep',         '07:00', 30,  'Personal'),
      _BlockDef('Deep Work Session 1',  '07:30', 90,  'Work'),
      _BlockDef('Short Break',          '09:00', 15,  'Personal'),
      _BlockDef('Deep Work Session 2',  '09:15', 90,  'Work'),
      _BlockDef('Lunch',                '10:45', 60,  'Meals'),
      _BlockDef('Deep Work Session 3',  '11:45', 90,  'Work'),
      _BlockDef('Review & Notes',       '13:15', 30,  'Work'),
    ],
  ),
  _RecommendedTemplate(
    name: 'Study Session',
    category: 'Learning',
    schedule: 'any',
    description: 'Pomodoro-style study blocks with deliberate breaks for retention.',
    blocks: [
      _BlockDef('Set Goals & Plan',     '08:00', 20,  'Learning'),
      _BlockDef('Study Block 1',        '08:20', 50,  'Learning'),
      _BlockDef('Short Break',          '09:10', 10,  'Personal'),
      _BlockDef('Study Block 2',        '09:20', 50,  'Learning'),
      _BlockDef('Short Break',          '10:10', 10,  'Personal'),
      _BlockDef('Study Block 3',        '10:20', 50,  'Learning'),
      _BlockDef('Lunch Break',          '11:10', 60,  'Meals'),
      _BlockDef('Review & Make Notes',  '12:10', 50,  'Learning'),
    ],
  ),
  _RecommendedTemplate(
    name: 'Minimal Day',
    category: 'Personal',
    schedule: 'any',
    description: 'Essentials only — one key task, rest, and recovery.',
    blocks: [
      _BlockDef('Morning Routine',      '08:00', 30,  'Personal'),
      _BlockDef('One Key Task',         '09:00', 120, 'Work'),
      _BlockDef('Lunch',                '11:00', 60,  'Meals'),
      _BlockDef('Evening Walk',         '16:00', 45,  'Exercise'),
    ],
  ),
];

// ── Recommended Templates Tab ──────────────────────────────────────────────

class _RecommendedTemplates extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecommendedTemplates> createState() => _RecommendedTemplatesState();
}

class _RecommendedTemplatesState extends ConsumerState<_RecommendedTemplates> {
  final Set<int> _loading = {};

  Future<void> _useTemplate(BuildContext context, int index) async {
    setState(() => _loading.add(index));
    try {
      final t = _recommended[index];
      final repo = ref.read(plannerRepositoryProvider);
      final id = await repo.addRoutine(
        name: t.name,
        schedule: t.schedule,
        category: t.category,
        description: t.description,
      );
      for (int i = 0; i < t.blocks.length; i++) {
        final b = t.blocks[i];
        await repo.addRoutineBlock(
          routineId: id,
          title: b.title,
          startTime: b.startTime,
          durationMinutes: b.durationMinutes,
          category: b.category,
          sortOrder: i,
        );
      }
      if (!context.mounted) return;
      final routine = Routine(
        id: id,
        name: t.name,
        schedule: t.schedule,
        category: t.category,
        description: t.description,
        createdAt: DateTime.now(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TemplateDetailScreen(routine: routine)),
      );
    } finally {
      if (mounted) setState(() => _loading.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _recommended.length,
      itemBuilder: (_, i) {
        final t = _recommended[i];
        final (color, icon) = categoryStyle(t.category);
        final isLoading = _loading.contains(i);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.5), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      '${_schedLabel(t.schedule)}  •  ${t.blocks.length} activities',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (t.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        t.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                height: 32,
                child: OutlinedButton(
                  onPressed: isLoading ? null : () => _useTemplate(context, i),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text('Use', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _schedLabel(String s) => switch (s) {
        'weekdays' => 'Mon – Fri',
        'weekends' => 'Sat – Sun',
        _ => 'Any day',
      };
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.routine});
  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon) = categoryStyle(routine.category);
    final blocksAsync = ref.watch(routineBlocksProvider(routine.id));
    final blockCount = blocksAsync.value?.length ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TemplateDetailScreen(routine: routine)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.5), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: Colors.white, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(
                    '${_schedLabel(routine.schedule)}  •  $blockCount activit${blockCount == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  String _schedLabel(String s) => switch (s) {
        'weekdays' => 'Mon – Fri',
        'weekends' => 'Sat – Sun',
        _ => 'Any day',
      };
}

// ── Create Template Sheet ──────────────────────────────────────────────────

class _CreateTemplateSheet extends StatefulWidget {
  const _CreateTemplateSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _schedule = 'any';
  String _category = 'Work';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.ref.read(plannerRepositoryProvider).addRoutine(
          name: _nameCtrl.text.trim(),
          schedule: _schedule,
          category: _category,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
          const Text('Create Template',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _field(_nameCtrl, 'Template Name', Icons.grid_view_rounded),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _schedule,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Repeat', Icons.repeat_rounded),
            items: [
              DropdownMenuItem(value: 'any', child: const Text('Any day')),
              DropdownMenuItem(
                  value: 'weekdays', child: const Text('Mon – Fri')),
              DropdownMenuItem(
                  value: 'weekends', child: const Text('Sat – Sun')),
            ],
            onChanged: (v) => setState(() => _schedule = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Category', Icons.label_rounded),
            items: kCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          _field(_descCtrl, 'Description (optional)', Icons.notes_rounded),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _dec(label, icon),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
