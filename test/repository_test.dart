import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_notes/models/note.dart';
import 'package:meeting_notes/models/note_query.dart';
import 'package:meeting_notes/storage/file_repository.dart';
import 'package:meeting_notes/storage/note_repository.dart';
import 'package:meeting_notes/storage/sqlite_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Note note(String id, String title, String content, DateTime at, NoteCategory c) {
  final created = DateTime(2026, 1, 1, 12);
  return Note(
    id: id,
    title: title,
    content: content,
    dateTime: at,
    category: c,
    createdAt: created,
    updatedAt: created,
  );
}

final samples = [
  note('1', 'Планёрка отдела продаж', 'Коммерческое предложение для ВЕКТОРА',
      DateTime(2026, 10, 5, 9, 30), NoteCategory.meeting),
  note('2', 'Встреча с поставщиком', 'Скидка 7% при предоплате',
      DateTime(2026, 10, 4, 14, 0), NoteCategory.businessMeeting),
  note('3', 'Конференция', 'Электронный документооборот, 100% цифра',
      DateTime(2026, 9, 28, 11, 15), NoteCategory.conference),
  note('4', 'Совещание по бюджету', 'Сократить расходы',
      DateTime(2026, 9, 25, 10, 0), NoteCategory.meeting),
];

void main() {
  test('Note: JSON round-trip', () {
    for (final n in samples) {
      expect(Note.fromJson(n.toJson()), n);
    }
  });

  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('notes_test'));
  tearDown(() async => tmp.delete(recursive: true));

  sqfliteFfiInit();
  final backends = <String, Future<NoteRepository> Function()>{
    'SQLite': () => SqliteNoteRepository.open(
          factory: databaseFactoryFfi,
          path: '${tmp.path}/notes.db',
        ),
    'Файлы': () async => FileNoteRepository(Directory('${tmp.path}/notes')),
  };

  for (final MapEntry(key: name, value: open) in backends.entries) {
    group(name, () {
      late NoteRepository repo;
      setUp(() async {
        repo = await open();
        for (final n in samples) {
          await repo.create(n);
        }
      });
      tearDown(() => repo.close());

      Future<List<String>> ids(NoteQuery q) async =>
          (await repo.search(q)).map((n) => n.id).toList();

      test('создание и сортировка от новых к старым', () async {
        expect(await ids(const NoteQuery()), ['1', '2', '3', '4']);
        expect(await repo.getById('2'), samples[1]);
      });

      test('редактирование', () async {
        final edited = samples[0].copyWith(title: 'Новый заголовок');
        await repo.update(edited);
        expect(await repo.getById('1'), edited);
        expect((await repo.getAll()).length, 4);
      });

      test('удаление', () async {
        await repo.delete('3');
        expect(await repo.getById('3'), isNull);
        expect(await ids(const NoteQuery()), ['1', '2', '4']);
      });

      test('поиск по ключевым словам без учёта регистра (кириллица)', () async {
        expect(await ids(const NoteQuery(text: 'вектора')), ['1']);
        expect(await ids(const NoteQuery(text: 'СОВЕЩАНИЕ')), ['4']);
        expect(await ids(const NoteQuery(text: 'скидка предоплате')), ['2']);
        expect(await ids(const NoteQuery(text: 'скидка бюджет')), isEmpty);
        expect(await ids(const NoteQuery(text: '100%')), ['3']);
        expect(await ids(const NoteQuery(text: '7%')), ['2']);
      });

      test('поиск по дате, времени и типу', () async {
        expect(await ids(const NoteQuery(dateFrom: '2026-10-04', dateTo: '2026-10-04')), ['2']);
        expect(await ids(const NoteQuery(dateTo: '2026-09-30')), ['3', '4']);
        expect(await ids(const NoteQuery(timeFrom: '10:00', timeTo: '12:00')), ['3', '4']);
        expect(await ids(const NoteQuery(category: NoteCategory.meeting)), ['1', '4']);
        expect(
          await ids(const NoteQuery(
              text: 'расходы', dateFrom: '2026-09-01', category: NoteCategory.meeting)),
          ['4'],
        );
      });

      test('upsert', () async {
        final extra = note('5', 'Собрание', '', DateTime(2026, 10, 6, 8), NoteCategory.assembly);
        await repo.upsert(extra);
        await repo.upsert(extra.copyWith(content: 'обновлено'));
        expect((await repo.getById('5'))!.content, 'обновлено');
        expect((await repo.getAll()).length, 5);
      });
    });
  }
}
