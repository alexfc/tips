import 'package:flutter/material.dart';

import '../models/note.dart';
import 'formatting.dart';
import 'highlight_text.dart';

String excerpt(String text, List<String> words, {int before = 40}) {
  final flat = text.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  if (words.isEmpty) return text;
  final lower = flat.toLowerCase();
  final positions =
      words.map(lower.indexOf).where((i) => i >= 0).toList()..sort();
  if (positions.isEmpty || positions.first <= before) return flat;
  var start = positions.first - before;
  final space = flat.indexOf(' ', start);
  if (space >= 0 && space < positions.first) start = space + 1;
  return '...${flat.substring(start)}';
}

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.words,
    required this.onTap,
  });

  final Note note;
  final List<String> words;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Icon(note.category.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightText(
                      note.title,
                      words: words,
                      maxLines: 2,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTime(note.dateTime)} - ${note.category.label}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: scheme.primary),
                    ),
                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      HighlightText(
                        excerpt(note.content, words),
                        words: words,
                        maxLines: 2,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
