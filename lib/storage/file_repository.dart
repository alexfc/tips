import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/note.dart';
import '../models/note_query.dart';
import 'note_repository.dart';

class FileNoteRepository extends NoteRepository {
  FileNoteRepository(this.directory);

  final Directory directory;

  @override
  String get location => directory.path;

  File _file(String id) => File(p.join(directory.path, '$id.json'));

  Future<void> _write(Note note) async {
    await directory.create(recursive: true);
    final target = _file(note.id);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(note.toJson()),
      flush: true,
    );
    await tmp.rename(target.path);
  }

  Future<Note?> _read(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      return Note.fromJson(Map<String, Object?>.from(json as Map));
    } on Object {
      return null;
    }
  }

  @override
  Future<List<Note>> search(NoteQuery query) async {
    if (!await directory.exists()) return [];
    final notes = <Note>[];
    await for (final entity in directory.list()) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      final note = await _read(entity);
      if (note != null && query.matches(note)) notes.add(note);
    }
    notes.sort(compareNotesDesc);
    return notes;
  }

  @override
  Future<Note?> getById(String id) async {
    final file = _file(id);
    return await file.exists() ? _read(file) : null;
  }

  @override
  Future<void> create(Note note) => _write(note);

  @override
  Future<void> update(Note note) => _write(note);

  @override
  Future<void> delete(String id) async {
    final file = _file(id);
    if (await file.exists()) await file.delete();
  }
}
