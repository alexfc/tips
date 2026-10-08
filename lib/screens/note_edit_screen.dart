import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../state/notes_provider.dart';
import '../widgets/formatting.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late DateTime _date;
  late TimeOfDay _time;
  late NoteCategory _category;
  bool _saving = false;

  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    final now = DateTime.now();
    _title = TextEditingController(text: note?.title);
    _content = TextEditingController(text: note?.content);
    _date = note?.dateTime ?? now;
    _time = TimeOfDay.fromDateTime(note?.dateTime ?? now);
    _category = note?.category ?? NoteCategory.meeting;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  DateTime get _dateTime =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  bool get _changed {
    final note = widget.note;
    if (note == null) {
      return _title.text.trim().isNotEmpty || _content.text.trim().isNotEmpty;
    }
    return _title.text.trim() != note.title ||
        _content.text.trim() != note.content ||
        _dateTime != note.dateTime ||
        _category != note.category;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<NotesProvider>();
    final title = _title.text.trim();
    final content = _content.text.trim();
    final Note saved;
    if (_isNew) {
      saved = await provider.create(
        title: title,
        content: content,
        dateTime: _dateTime,
        category: _category,
      );
    } else {
      saved = await provider.update(widget.note!.copyWith(
        title: title,
        content: content,
        dateTime: _dateTime,
        category: _category,
      ));
    }
    if (mounted) Navigator.pop(context, saved);
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await confirm(
      context,
      title: 'Отменить изменения?',
      message: 'Несохранённые изменения будут потеряны.',
      confirmLabel: 'Не сохранять',
      destructive: true,
    );
    if (discard && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _saving || !_changed,
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'Новая заметка' : 'Редактирование'),
          actions: [
            IconButton(
              tooltip: 'Сохранить',
              icon: const Icon(Icons.check),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Заголовок *',
                  hintText: 'Например: Планёрка отдела',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите заголовок' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NoteCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Тип мероприятия'),
                items: [
                  for (final c in NoteCategory.values)
                    DropdownMenuItem(
                      value: c,
                      child: Row(children: [
                        Icon(c.icon, size: 20),
                        const SizedBox(width: 12),
                        Text(c.label),
                      ]),
                    ),
                ],
                onChanged: (c) => setState(() => _category = c!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _PickerField(
                      label: 'Дата',
                      icon: Icons.calendar_today_outlined,
                      value: formatDate(_date),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _PickerField(
                      label: 'Время',
                      icon: Icons.schedule,
                      value: formatTimeOfDay(_time),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _content,
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  hintText: 'Повестка, решения, задачи, ответственные...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, suffixIcon: Icon(icon)),
        child: Text(value),
      ),
    );
  }
}
