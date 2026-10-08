import 'note.dart';

class NoteQuery {
  const NoteQuery({
    this.text = '',
    this.dateFrom,
    this.dateTo,
    this.timeFrom,
    this.timeTo,
    this.category,
  });

  final String text;

  final String? dateFrom;
  final String? dateTo;

  final String? timeFrom;
  final String? timeTo;

  final NoteCategory? category;

  List<String> get words => text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  bool get hasFilters =>
      dateFrom != null ||
      dateTo != null ||
      timeFrom != null ||
      timeTo != null ||
      category != null;

  bool get isEmpty => words.isEmpty && !hasFilters;

  NoteQuery withText(String value) => NoteQuery(
        text: value,
        dateFrom: dateFrom,
        dateTo: dateTo,
        timeFrom: timeFrom,
        timeTo: timeTo,
        category: category,
      );

  NoteQuery withoutFilters() => NoteQuery(text: text);

  bool matches(Note note) {
    final haystack = '${note.title}\n${note.content}'.toLowerCase();
    if (!words.every(haystack.contains)) return false;
    final date = note.dateKey;
    final time = note.timeKey;
    if (dateFrom != null && date.compareTo(dateFrom!) < 0) return false;
    if (dateTo != null && date.compareTo(dateTo!) > 0) return false;
    if (timeFrom != null && time.compareTo(timeFrom!) < 0) return false;
    if (timeTo != null && time.compareTo(timeTo!) > 0) return false;
    if (category != null && note.category != category) return false;
    return true;
  }
}
