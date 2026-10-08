import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meeting_notes/main.dart';
import 'package:meeting_notes/models/note.dart';
import 'package:meeting_notes/models/note_query.dart';
import 'package:meeting_notes/state/notes_provider.dart';
import 'package:meeting_notes/storage/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryRepository extends NoteRepository {
  final _notes = <String, Note>{};

  @override
  String get location => 'memory';

  @override
  Future<List<Note>> search(NoteQuery query) async =>
      _notes.values.where(query.matches).toList()..sort(compareNotesDesc);

  @override
  Future<Note?> getById(String id) async => _notes[id];

  @override
  Future<void> create(Note note) async => _notes[note.id] = note;

  @override
  Future<void> update(Note note) async => _notes[note.id] = note;

  @override
  Future<void> delete(String id) async => _notes.remove(id);
}

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'ru';
    await initializeDateFormatting('ru');
  });

  testWidgets('создание, поиск, редактирование и удаление через интерфейс',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider =
        NotesProvider(repositoryFactory: (_) async => MemoryRepository());
    await provider.init();
    await tester.pumpWidget(MeetingNotesApp(provider: provider));
    expect(find.text('Заметок пока нет'), findsOneWidget);

    await tester.tap(find.text('Новая заметка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить').last);
    await tester.pumpAndSettle();
    expect(find.text('Введите заголовок'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Заголовок *'), 'Планёрка');
    await tester.enterText(find.widgetWithText(TextFormField, 'Содержание'), 'Обсудить бюджет');
    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Планёрка'), findsOneWidget);
    expect(provider.notes.single.content, 'Обсудить бюджет');

    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'отпуск');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'бюджет');
    await tester.pumpAndSettle();
    expect(provider.notes.length, 1);
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Планёрка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Редактировать'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Заголовок *'), 'Планёрка отдела');
    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Планёрка отдела'), findsOneWidget);

    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(provider.notes, isEmpty);
    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(provider.notes.single.title, 'Планёрка отдела');
  });
}
