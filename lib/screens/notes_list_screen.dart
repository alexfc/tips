import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../models/note_query.dart';
import '../state/notes_provider.dart';
import '../widgets/formatting.dart';
import '../widgets/note_card.dart';
import 'note_edit_screen.dart';
import 'note_view_screen.dart';
import 'search_filter_sheet.dart';
import 'settings_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  final _hiddenIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  NotesProvider get _provider => context.read<NotesProvider>();

  void _closeSearch() {
    _searchController.clear();
    setState(() => _searching = false);
    _provider.setQuery(_provider.query.withText(''));
  }

  Future<void> _openFilters() async {
    final query = await showSearchFilterSheet(context, _provider.query);
    if (query != null) {
      await _provider.setQuery(query.withText(_searchController.text));
    }
  }

  Future<void> _createNote() async {
    final note = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditScreen()),
    );
    if (note != null && mounted) showMessage(context, 'Заметка создана');
  }

  Future<void> _openNote(Note note) async {
    final deleted = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteViewScreen(note: note)),
    );
    if (deleted != null && mounted) _showUndo(deleted);
  }

  void _showUndo(Note deleted) {
    final provider = _provider;
    showMessage(
      context,
      'Заметка "${deleted.title}" удалена',
      action: SnackBarAction(
        label: 'Отменить',
        onPressed: () => provider.restore(deleted),
      ),
    );
  }

  Future<void> _dismiss(Note note) async {
    setState(() => _hiddenIds.add(note.id));
    await _provider.delete(note);
    if (!mounted) return;
    setState(() => _hiddenIds.remove(note.id));
    _showUndo(note);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final query = provider.query;
    final notes =
        provider.notes.where((n) => !_hiddenIds.contains(n.id)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: _searching
            ? IconButton(
                tooltip: 'Закрыть поиск',
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeSearch,
              )
            : null,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск по ключевым словам',
                  border: InputBorder.none,
                ),
                onChanged: (text) => provider.setQuery(query.withText(text)),
              )
            : const Text('Заметки'),
        actions: [
          if (!_searching)
            IconButton(
              tooltip: 'Поиск',
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              tooltip: 'Очистить',
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                provider.setQuery(query.withText(''));
              },
            ),
          IconButton(
            tooltip: 'Фильтры',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: query.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
          ),
          if (!_searching)
            IconButton(
              tooltip: 'Настройки',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (query.hasFilters) _FilterChips(query: query),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? _EmptyState(filtered: !query.isEmpty)
                    : _NotesList(
                        notes: notes,
                        words: query.words,
                        onOpen: _openNote,
                        onDismiss: _dismiss,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNote,
        icon: const Icon(Icons.add),
        label: const Text('Новая заметка'),
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.words,
    required this.onOpen,
    required this.onDismiss,
  });

  final List<Note> notes;
  final List<String> words;
  final ValueChanged<Note> onOpen;
  final ValueChanged<Note> onDismiss;

  @override
  Widget build(BuildContext context) {
    final items = <Object>[];
    String? lastDay;
    for (final note in notes) {
      if (note.dateKey != lastDay) {
        lastDay = note.dateKey;
        items.add(dayHeader(note.dateTime));
      }
      items.add(note);
    }
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              item,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          );
        }
        final note = item as Note;
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            color: theme.colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                color: theme.colorScheme.onErrorContainer),
          ),
          confirmDismiss: (_) => confirm(
            context,
            title: 'Удалить заметку?',
            message: '"${note.title}" будет удалена.',
            confirmLabel: 'Удалить',
            destructive: true,
          ),
          onDismissed: (_) => onDismiss(note),
          child: NoteCard(
            note: note,
            words: words,
            onTap: () => onOpen(note),
          ),
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.query});

  final NoteQuery query;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();
    final labels = <String>[
      if (query.dateFrom != null || query.dateTo != null)
        'Даты: ${_range(query.dateFrom, query.dateTo, _date)}',
      if (query.timeFrom != null || query.timeTo != null)
        'Время: ${_range(query.timeFrom, query.timeTo, (s) => s)}',
      if (query.category != null) query.category!.label,
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final label in labels)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(label: Text(label)),
            ),
          ActionChip(
            avatar: const Icon(Icons.close, size: 18),
            label: const Text('Сбросить'),
            onPressed: () => provider.setQuery(query.withoutFilters()),
          ),
        ],
      ),
    );
  }

  static String _date(String key) => formatDate(DateTime.parse(key));

  static String _range(String? from, String? to, String Function(String) f) {
    if (from != null && to != null) {
      return from == to ? f(from) : '${f(from)} - ${f(to)}';
    }
    return from != null ? 'с ${f(from)}' : 'по ${f(to!)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off : Icons.edit_note,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? 'Ничего не найдено' : 'Заметок пока нет',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? 'Измените ключевые слова или сбросьте фильтры'
                  : 'Нажмите "Новая заметка", чтобы записать итоги совещания, '
                      'собрания или встречи',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
