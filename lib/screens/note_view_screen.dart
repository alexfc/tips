import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../state/notes_provider.dart';
import '../widgets/formatting.dart';
import 'note_edit_screen.dart';

class NoteViewScreen extends StatefulWidget {
  const NoteViewScreen({super.key, required this.note});

  final Note note;

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  late Note _note = widget.note;

  Future<void> _edit() async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditScreen(note: _note)),
    );
    if (updated != null && mounted) {
      setState(() => _note = updated);
      showMessage(context, 'Изменения сохранены');
    }
  }

  Future<void> _delete() async {
    final ok = await confirm(
      context,
      title: 'Удалить заметку?',
      message: '"${_note.title}" будет удалена.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<NotesProvider>().delete(_note);
    if (mounted) Navigator.pop(context, _note);
  }

  void _share() {
    final text = StringBuffer()
      ..writeln(_note.title)
      ..writeln('${_note.category.label}, ${formatDateTime(_note.dateTime)}')
      ..writeln()
      ..write(_note.content);
    SharePlus.instance.share(ShareParams(text: text.toString(), subject: _note.title));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметка'),
        actions: [
          IconButton(
            tooltip: 'Поделиться',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          SelectableText(_note.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(_note.category.icon, size: 18),
                label: Text(_note.category.label),
              ),
              Chip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(formatDateTime(_note.dateTime)),
              ),
            ],
          ),
          const Divider(height: 32),
          SelectableText(
            _note.content.isEmpty ? 'Без содержания' : _note.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              color: _note.content.isEmpty ? scheme.outline : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Создано: ${formatDateTime(_note.createdAt)}\n'
            'Изменено: ${formatDateTime(_note.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Редактировать'),
      ),
    );
  }
}
