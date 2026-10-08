import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime d) => DateFormat('d MMMM y', 'ru').format(d);

String formatTime(DateTime d) => DateFormat('HH:mm', 'ru').format(d);

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTimeKey(String key) {
  final parts = key.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String dayHeader(DateTime d) {
  final now = DateTime.now();
  final day = DateTime(d.year, d.month, d.day);
  final diff = day.difference(DateTime(now.year, now.month, now.day)).inDays;
  final weekday = DateFormat('EEEE', 'ru').format(d);
  return switch (diff) {
    0 => 'Сегодня, $weekday',
    -1 => 'Вчера, $weekday',
    1 => 'Завтра, $weekday',
    _ => '${formatDate(d)}, $weekday',
  };
}

void showMessage(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
