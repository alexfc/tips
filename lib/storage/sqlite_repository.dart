import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import '../models/note_query.dart';
import 'note_repository.dart';

class SqliteNoteRepository extends NoteRepository {
  SqliteNoteRepository._(this._db, this.location);

  static const _table = 'notes';

  final Database _db;

  @override
  final String location;

  static Future<SqliteNoteRepository> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              date TEXT NOT NULL,
              time TEXT NOT NULL,
              category TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              search_text TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_notes_date ON $_table(date, time)');
        },
      ),
    );
    return SqliteNoteRepository._(db, path);
  }

  Map<String, Object?> _toRow(Note note) => {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'date': note.dateKey,
        'time': note.timeKey,
        'category': note.category.name,
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': note.updatedAt.toIso8601String(),
        'search_text': '${note.title}\n${note.content}'.toLowerCase(),
      };

  Note _fromRow(Map<String, Object?> row) => Note.fromJson({
        'id': row['id'],
        'title': row['title'],
        'content': row['content'],
        'date': row['date'],
        'time': row['time'],
        'category': row['category'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });

  @override
  Future<List<Note>> search(NoteQuery query) async {
    final where = <String>[];
    final args = <Object?>[];
    for (final word in query.words) {
      where.add(r"search_text LIKE ? ESCAPE '\'");
      final escaped = word
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');
      args.add('%$escaped%');
    }
    void add(String clause, Object? value) {
      if (value == null) return;
      where.add(clause);
      args.add(value);
    }

    add('date >= ?', query.dateFrom);
    add('date <= ?', query.dateTo);
    add('time >= ?', query.timeFrom);
    add('time <= ?', query.timeTo);
    add('category = ?', query.category?.name);

    final rows = await _db.query(
      _table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC, time DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Note?> getById(String id) async {
    final rows = await _db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> create(Note note) => _db.insert(_table, _toRow(note));

  @override
  Future<void> update(Note note) =>
      _db.update(_table, _toRow(note), where: 'id = ?', whereArgs: [note.id]);

  @override
  Future<void> delete(String id) =>
      _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> close() => _db.close();
}
