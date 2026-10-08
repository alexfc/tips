import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../models/note_query.dart';
import '../widgets/formatting.dart';

Future<NoteQuery?> showSearchFilterSheet(BuildContext context, NoteQuery query) {
  return showModalBottomSheet<NoteQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SearchFilterSheet(initial: query),
  );
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({required this.initial});

  final NoteQuery initial;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  static final _keyFormat = DateFormat('yyyy-MM-dd');

  late DateTime? _dateFrom = _parse(widget.initial.dateFrom);
  late DateTime? _dateTo = _parse(widget.initial.dateTo);
  late TimeOfDay? _timeFrom = _parseTime(widget.initial.timeFrom);
  late TimeOfDay? _timeTo = _parseTime(widget.initial.timeTo);
  late NoteCategory? _category = widget.initial.category;

  static DateTime? _parse(String? key) => key == null ? null : DateTime.parse(key);
  static TimeOfDay? _parseTime(String? key) => key == null ? null : parseTimeKey(key);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Период',
    );
    if (range != null) {
      setState(() {
        _dateFrom = range.start;
        _dateTo = range.end;
      });
    }
  }

  void _setToday() {
    final now = DateTime.now();
    setState(() => _dateFrom = _dateTo = DateTime(now.year, now.month, now.day));
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay? initial, String help) => showTimePicker(
        context: context,
        initialTime: initial ?? const TimeOfDay(hour: 9, minute: 0),
        helpText: help,
      );

  void _apply() {
    var from = _timeFrom;
    var to = _timeTo;
    if (from != null && to != null && from.isAfter(to)) (from, to) = (to, from);
    Navigator.pop(
      context,
      NoteQuery(
        text: widget.initial.text,
        dateFrom: _dateFrom == null ? null : _keyFormat.format(_dateFrom!),
        dateTo: _dateTo == null ? null : _keyFormat.format(_dateTo!),
        timeFrom: from == null ? null : formatTimeOfDay(from),
        timeTo: to == null ? null : formatTimeOfDay(to),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = _dateFrom == null
        ? 'Любые'
        : _dateFrom == _dateTo
            ? formatDate(_dateFrom!)
            : '${formatDate(_dateFrom!)} - ${formatDate(_dateTo!)}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Фильтры поиска', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Дата мероприятия', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                InputChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(dates),
                  onPressed: _pickDates,
                  onDeleted: _dateFrom == null
                      ? null
                      : () => setState(() => _dateFrom = _dateTo = null),
                ),
                ActionChip(label: const Text('Сегодня'), onPressed: _setToday),
              ],
            ),
            const SizedBox(height: 16),
            Text('Время мероприятия', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                InputChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(_timeFrom == null ? 'С -' : 'С ${formatTimeOfDay(_timeFrom!)}'),
                  onPressed: () async {
                    final t = await _pickTime(_timeFrom, 'Время с');
                    if (t != null) setState(() => _timeFrom = t);
                  },
                  onDeleted: _timeFrom == null ? null : () => setState(() => _timeFrom = null),
                ),
                InputChip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(_timeTo == null ? 'До -' : 'До ${formatTimeOfDay(_timeTo!)}'),
                  onPressed: () async {
                    final t = await _pickTime(_timeTo, 'Время до');
                    if (t != null) setState(() => _timeTo = t);
                  },
                  onDeleted: _timeTo == null ? null : () => setState(() => _timeTo = null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Тип мероприятия', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final c in NoteCategory.values)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.label),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, widget.initial.withoutFilters()),
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
