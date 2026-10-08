import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../models/note_query.dart';
import '../storage/file_repository.dart';
import '../storage/note_repository.dart';
import '../storage/sqlite_repository.dart';

enum StorageType {
  sqlite('База данных SQLite', 'Все заметки в одном файле базы данных'),
  files('Файлы на устройстве', 'Каждая заметка - отдельный JSON-файл');

  const StorageType(this.label, this.description);

  final String label;
  final String description;
}

typedef RepositoryFactory = Future<NoteRepository> Function(StorageType type);

Future<NoteRepository> defaultRepositoryFactory(StorageType type) async {
  switch (type) {
    case StorageType.sqlite:
      return SqliteNoteRepository.open(
        factory: databaseFactory,
        path: p.join(await getDatabasesPath(), 'notes.db'),
      );
    case StorageType.files:
      final docs = await getApplicationDocumentsDirectory();
      return FileNoteRepository(Directory(p.join(docs.path, 'notes')));
  }
}

class NotesProvider extends ChangeNotifier {
  NotesProvider({RepositoryFactory? repositoryFactory})
      : _factory = repositoryFactory ?? defaultRepositoryFactory;

  static const _storageKey = 'storage_type';
  static const exportFormat = 'meeting_notes_export';

  final RepositoryFactory _factory;
  final _uuid = const Uuid();

  late NoteRepository _repository;
  StorageType _storageType = StorageType.sqlite;
  NoteQuery _query = const NoteQuery();
  List<Note> _notes = [];
  bool _loading = true;

  StorageType get storageType => _storageType;
  String get storageLocation => _repository.location;
  NoteQuery get query => _query;
  List<Note> get notes => _notes;
  bool get loading => _loading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _storageType = StorageType.values.firstWhere(
      (t) => t.name == prefs.getString(_storageKey),
      orElse: () => StorageType.sqlite,
    );
    _repository = await _factory(_storageType);
    await refresh();
  }

  int _refreshId = 0;

  Future<void> refresh() async {
    final id = ++_refreshId;
    final notes = await _repository.search(_query);
    if (id != _refreshId) return;
    _notes = notes;
    _loading = false;
    notifyListeners();
  }

  Future<void> setQuery(NoteQuery query) async {
    _query = query;
    await refresh();
  }

  Future<Note> create({
    required String title,
    required String content,
    required DateTime dateTime,
    required NoteCategory category,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      dateTime: dateTime,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.create(note);
    await refresh();
    return note;
  }

  Future<Note> update(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _repository.update(updated);
    await refresh();
    return updated;
  }

  Future<void> delete(Note note) async {
    await _repository.delete(note.id);
    await refresh();
  }

  Future<void> restore(Note note) async {
    await _repository.upsert(note);
    await refresh();
  }

  Future<int> totalCount() async => (await _repository.getAll()).length;

  Future<int> switchStorage(StorageType type, {required bool copyExisting}) async {
    if (type == _storageType) return 0;
    final next = await _factory(type);
    var copied = 0;
    if (copyExisting) {
      for (final note in await _repository.getAll()) {
        await next.upsert(note);
        copied++;
      }
    }
    await _repository.close();
    _repository = next;
    _storageType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, type.name);
    await refresh();
    return copied;
  }

  Future<String> exportJson() async {
    final notes = await _repository.getAll();
    return const JsonEncoder.withIndent('  ').convert({
      'format': exportFormat,
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => n.toJson()).toList(),
    });
  }

  Future<int> importJson(String source) async {
    final Object? data;
    try {
      data = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Файл не является JSON-документом');
    }
    if (data is! Map || data['format'] != exportFormat || data['notes'] is! List) {
      throw const FormatException('Файл не является экспортом заметок');
    }
    final notes = <Note>[];
    try {
      for (final item in data['notes'] as List) {
        notes.add(Note.fromJson(Map<String, Object?>.from(item as Map)));
      }
    } on Object {
      throw const FormatException('Файл экспорта повреждён');
    }
    for (final note in notes) {
      await _repository.upsert(note);
    }
    await refresh();
    return notes.length;
  }

  Future<void> addDemoNotes() async {
    final today = DateTime.now();
    DateTime at(int daysAgo, int hour, int minute) =>
        DateTime(today.year, today.month, today.day - daysAgo, hour, minute);
    final samples = [
      (
        'Планёрка отдела продаж',
        'Итоги недели: план выполнен на 104%.\n'
            'Задачи: подготовить коммерческое предложение для ООО "Вектор" до пятницы, '
            'обновить прайс-лист.\nОтветственный: Иванова А.',
        at(0, 9, 30),
        NoteCategory.meeting,
      ),
      (
        'Встреча с поставщиком',
        'Обсудили сроки поставки оборудования - 14 рабочих дней. '
            'Скидка 7% при предоплате. Нужно согласовать договор с юристами.',
        at(1, 14, 0),
        NoteCategory.businessMeeting,
      ),
      (
        'Общее собрание коллектива',
        'Повестка: график отпусков, переезд в новый офис, корпоратив.\n'
            'Решение: переезд запланирован на следующий месяц.',
        at(3, 16, 0),
        NoteCategory.assembly,
      ),
      (
        'Конференция "Цифровая трансформация"',
        'Доклад о внедрении электронного документооборота. '
            'Полезные идеи: автоматизация согласования договоров, '
            'электронная подпись для внутренних документов.',
        at(7, 11, 15),
        NoteCategory.conference,
      ),
      (
        'Совещание по бюджету на квартал',
        'Сократить расходы на командировки на 10%. '
            'Выделить бюджет на обучение сотрудников. Следующее совещание через две недели.',
        at(10, 10, 0),
        NoteCategory.meeting,
      ),
    ];
    final now = DateTime.now();
    for (final (title, content, dateTime, category) in samples) {
      await _repository.create(Note(
        id: _uuid.v4(),
        title: title,
        content: content,
        dateTime: dateTime,
        category: category,
        createdAt: now,
        updatedAt: now,
      ));
    }
    await refresh();
  }

  Future<void> deleteAll() async {
    for (final note in await _repository.getAll()) {
      await _repository.delete(note.id);
    }
    await refresh();
  }
}
