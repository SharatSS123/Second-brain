import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../providers/notes_providers.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allNotesProvider);
    final repo = ref.read(notesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.sort), onPressed: () {}),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notes yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap + to create your first note', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final note = notes[i];
              return Card(
                child: ListTile(
                  leading: note.isPinned
                      ? const Icon(Icons.push_pin, color: Colors.amber)
                      : null,
                  title: Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => repo.delete(note.id),
                  ),
                  onTap: () => _showEditor(context, note),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context),
        icon: const Icon(Icons.edit),
        label: const Text('New Note'),
      ),
    );
  }

  void _showEditor(BuildContext context, [NotesTableData? note]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _NoteEditorScreen(note: note)),
    );
  }
}

class _NoteEditorScreen extends ConsumerStatefulWidget {
  final NotesTableData? note;
  const _NoteEditorScreen({this.note});

  @override
  ConsumerState<_NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<_NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        actions: [
          IconButton(icon: const Icon(Icons.tag), onPressed: () {}),
          IconButton(icon: const Icon(Icons.pin_outlined), onPressed: () {}),
          FilledButton(onPressed: _save, child: const Text('Save')),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start writing...',
                  border: InputBorder.none,
                ),
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    try {
      final repo = ref.read(notesRepositoryProvider);
      if (widget.note == null) {
        await repo.add(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      } else {
        await repo.update(
          widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }
}
