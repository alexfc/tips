import '../models/note.dart';
import '../models/note_query.dart';

abstract class NoteRepository {
  String get location;

  Future<List<Note>> search(NoteQuery query);

  Future<List<Note>> getAll() => search(const NoteQuery());

  Future<Note?> getById(String id);

  Future<void> create(Note note);

  Future<void> update(Note note);

  Future<void> delete(String id);

  Future<void> upsert(Note note) async {
    if (await getById(note.id) == null) {
      await create(note);
    } else {
      await update(note);
    }
  }

  Future<void> close() async {}
}

int compareNotesDesc(Note a, Note b) => b.dateTime.compareTo(a.dateTime);
