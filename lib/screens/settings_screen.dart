import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state/notes_provider.dart';
import '../widgets/formatting.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _changeStorage(BuildContext context, StorageType? type) async {
    final provider = context.read<NotesProvider>();
    if (type == null || type == provider.storageType) return;
    final copy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переключиться на "${type.label}"?'),
        content: const Text(
          'Перенести существующие заметки в новое хранилище? '
          'Заметки в текущем хранилище сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Не переносить'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Перенести'),
          ),
        ],
      ),
    );
    if (copy == null) return;
    final copied = await provider.switchStorage(type, copyExisting: copy);
    if (context.mounted) {
      showMessage(
        context,
        copy
            ? 'Хранилище изменено, перенесено заметок: $copied'
            : 'Хранилище изменено',
      );
    }
  }

  Future<void> _export(BuildContext context) async {
    final provider = context.read<NotesProvider>();
    final box = context.findRenderObject() as RenderBox?;
    final json = await provider.exportJson();
    final dir = await getTemporaryDirectory();
    final name =
        'notes_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
    final file = File(p.join(dir.path, name));
    await file.writeAsString(json);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Экспорт заметок',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  Future<void> _import(BuildContext context) async {
    final provider = context.read<NotesProvider>();
    final files = await FilePicker.pickFiles(dialogTitle: 'Файл экспорта заметок');
    if (files.isEmpty) return;
    try {
      final count = await provider.importJson(await files.first.xFile.readAsString());
      if (context.mounted) showMessage(context, 'Импортировано заметок: $count');
    } on FormatException catch (e) {
      if (context.mounted) showMessage(context, 'Ошибка импорта: ${e.message}');
    }
  }

  Future<void> _deleteAll(BuildContext context) async {
    final provider = context.read<NotesProvider>();
    final ok = await confirm(
      context,
      title: 'Удалить все заметки?',
      message: 'Будут удалены все заметки в хранилище "${provider.storageType.label}". '
          'Действие нельзя отменить.',
      confirmLabel: 'Удалить все',
      destructive: true,
    );
    if (!ok) return;
    await provider.deleteAll();
    if (context.mounted) showMessage(context, 'Все заметки удалены');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final theme = Theme.of(context);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(text,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          header('Способ хранения заметок'),
          RadioGroup<StorageType>(
            groupValue: provider.storageType,
            onChanged: (type) => _changeStorage(context, type),
            child: Column(
              children: [
                for (final type in StorageType.values)
                  RadioListTile<StorageType>(
                    value: type,
                    title: Text(type.label),
                    subtitle: Text(type.description),
                    secondary: Icon(type == StorageType.sqlite
                        ? Icons.storage_outlined
                        : Icons.folder_outlined),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Расположение данных'),
            subtitle: SelectableText(provider.storageLocation),
          ),
          const Divider(),
          header('Перенос между устройствами'),
          Builder(
            builder: (context) => ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Экспорт заметок'),
              subtitle: const Text(
                  'Сохранить в файл JSON и отправить в облако, почту или мессенджер'),
              onTap: () => _export(context),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Импорт заметок'),
            subtitle: const Text('Загрузить заметки из файла экспорта'),
            onTap: () => _import(context),
          ),
          const Divider(),
          header('Данные'),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Добавить примеры заметок'),
            subtitle: const Text('5 демонстрационных заметок для проверки поиска'),
            onTap: () async {
              await provider.addDemoNotes();
              if (context.mounted) showMessage(context, 'Примеры добавлены');
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
            title: Text('Удалить все заметки',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _deleteAll(context),
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.help_outline),
            applicationName: 'Заметки для совещаний',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Кейс-задача №4. Учебная практика.',
            child: Text('О приложении'),
          ),
        ],
      ),
    );
  }
}
