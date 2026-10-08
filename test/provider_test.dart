import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_notes/models/note.dart';
import 'package:meeting_notes/models/note_query.dart';
import 'package:meeting_notes/state/notes_provider.dart';
import 'package:meeting_notes/storage/file_repository.dart';
import 'package:meeting_notes/storage/sqlite_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tmp;
  late NotesProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    tmp = await Directory.systemTemp.createTemp('provider_test');
    provider = NotesProvider(repositoryFactory: (type) async => switch (type) {
          StorageType.sqlite => SqliteNoteRepository.open(
              factory: databaseFactoryFfi, path: '${tmp.path}/notes.db'),
          StorageType.files => FileNoteRepository(Directory('${tmp.path}/files')),
        });
    await provider.init();
  });
  tearDown(() async => tmp.delete(recursive: true));

  test('CRUD, поиск и отмена удаления', () async {
    final n = await provider.create(
      title: 'Планёрка',
      content: 'Итоги недели',
      dateTime: DateTime(2026, 10, 5, 9),
      category: NoteCategory.meeting,
    );
    expect(provider.notes, [n]);

    final edited = await provider.update(n.copyWith(title: 'Планёрка отдела'));
    expect(provider.notes.single.title, 'Планёрка отдела');

    await provider.setQuery(const NoteQuery(text: 'итоги'));
    expect(provider.notes.length, 1);
    await provider.setQuery(const NoteQuery(text: 'отпуск'));
    expect(provider.notes, isEmpty);
    await provider.setQuery(const NoteQuery());

    await provider.delete(edited);
    expect(provider.notes, isEmpty);
    await provider.restore(edited);
    expect(provider.notes, [edited]);
  });

  test('переключение хранилища с переносом заметок', () async {
    await provider.addDemoNotes();
    expect(await provider.switchStorage(StorageType.files, copyExisting: true), 5);
    expect(provider.storageType, StorageType.files);
    expect(provider.notes.length, 5);
    expect(Directory('${tmp.path}/files').listSync().length, 5);

    await provider.switchStorage(StorageType.sqlite, copyExisting: false);
    expect(provider.notes.length, 5);
  });

  test('экспорт и импорт', () async {
    await provider.addDemoNotes();
    final json = await provider.exportJson();
    await provider.deleteAll();
    expect(provider.notes, isEmpty);
    expect(await provider.importJson(json), 5);
    expect(provider.notes.length, 5);
    await provider.importJson(json);
    expect(provider.notes.length, 5);
    expect(() => provider.importJson('{"a": 1}'), throwsFormatException);
    expect(() => provider.importJson('не json'), throwsFormatException);
  });
}
