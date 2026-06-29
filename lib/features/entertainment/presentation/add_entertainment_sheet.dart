import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/entertainment_providers.dart';

class AddEntertainmentSheet extends ConsumerStatefulWidget {
  final String type; // 'Movie' or 'TV Series'

  const AddEntertainmentSheet({super.key, required this.type});

  @override
  ConsumerState<AddEntertainmentSheet> createState() => _AddEntertainmentSheetState();
}

class _AddEntertainmentSheetState extends ConsumerState<AddEntertainmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _genreController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  static const _genres = [
    'Action', 'Adventure', 'Animation', 'Comedy', 'Crime',
    'Documentary', 'Drama', 'Fantasy', 'Horror', 'Mystery',
    'Romance', 'Sci-Fi', 'Thriller', 'Western',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _genreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.type == 'Movie' ? 'Movie' : 'Series';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Add to Watchlist',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.type,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: '$label title *',
                hintText: 'e.g. Inception',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  widget.type == 'Movie' ? Icons.movie_outlined : Icons.tv_outlined,
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),

            // Year + Genre row
            Row(
              children: [
                // Year
                SizedBox(
                  width: 110,
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      hintText: '2024',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final y = int.tryParse(v);
                      if (y == null || y < 1900 || y > DateTime.now().year + 5) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Genre
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _genres;
                      return _genres.where(
                        (g) => g.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                      );
                    },
                    onSelected: (g) => _genreController.text = g,
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                      // Keep our controller in sync
                      controller.text = _genreController.text;
                      controller.addListener(() => _genreController.text = controller.text);
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Genre',
                          hintText: 'e.g. Sci-Fi',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Recommended by, where to watch...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Add to Watchlist'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(entertainmentRepositoryProvider).add(
            title: _titleController.text.trim(),
            type: widget.type,
            genre: _genreController.text.trim().isNotEmpty ? _genreController.text.trim() : null,
            year: _yearController.text.isNotEmpty ? int.tryParse(_yearController.text) : null,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}
